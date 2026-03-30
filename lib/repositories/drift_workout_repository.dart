import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/workout_session.dart' as model;
import 'workout_repository.dart';

class DriftWorkoutRepository implements WorkoutRepository {
  final AppDatabase db;

  DriftWorkoutRepository(this.db);

  @override
  Future<List<model.WorkoutSession>> getAllSessions() async {
    final sessionRows = await (db.select(
      db.workoutSessions,
    )..orderBy([(tbl) => OrderingTerm.desc(tbl.startedAt)])).get();

    if (sessionRows.isEmpty) {
      return [];
    }

    final exerciseRows = await db.select(db.workoutExercises).get();
    final setRows = await db.select(db.workoutSets).get();

    final Map<int, List<WorkoutSet>> setsByExerciseId = {};
    for (final setRow in setRows) {
      setsByExerciseId
          .putIfAbsent(setRow.workoutExerciseId, () => [])
          .add(setRow);
    }

    final Map<String, List<WorkoutExercise>> exercisesBySessionId = {};
    for (final exerciseRow in exerciseRows) {
      exercisesBySessionId
          .putIfAbsent(exerciseRow.sessionId, () => [])
          .add(exerciseRow);
    }

    final sessions = <model.WorkoutSession>[];

    for (final sessionRow in sessionRows) {
      final sessionExercises = exercisesBySessionId[sessionRow.id] ?? [];
      sessionExercises.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      final exercises = sessionExercises.map((exerciseRow) {
        final exerciseSets = setsByExerciseId[exerciseRow.id] ?? [];
        exerciseSets.sort((a, b) => a.setNumber.compareTo(b.setNumber));

        return model.WorkoutExerciseRecord(
          exerciseId: exerciseRow.exerciseId,
          exerciseName: exerciseRow.exerciseName,
          muscleGroup: exerciseRow.muscleGroup,
          tags: _decodeStringList(exerciseRow.tagsJson),
          isCustom: exerciseRow.isCustom,
          sets: exerciseSets
              .map(
                (setRow) => model.WorkoutSetRecord(
                  setNumber: setRow.setNumber,
                  reps: setRow.reps,
                  weight: setRow.weight,
                  restSeconds: setRow.restSeconds,
                  createdAt: setRow.createdAt,
                  isWarmup: setRow.isWarmup,
                ),
              )
              .toList(),
        );
      }).toList();

      sessions.add(
        model.WorkoutSession(
          id: sessionRow.id,
          routineId: sessionRow.routineId,
          routineName: sessionRow.routineName,
          startedAt: sessionRow.startedAt,
          finishedAt: sessionRow.finishedAt,
          durationSeconds: sessionRow.durationSeconds,
          totalVolume: sessionRow.totalVolume,
          sessionTags: _decodeStringList(sessionRow.sessionTagsJson),
          notes: sessionRow.notes,
          exercises: exercises,
        ),
      );
    }

    return sessions;
  }

  @override
  Future<void> saveSession(model.WorkoutSession session) async {
    await db.transaction(() async {
      final existingExercises = await (db.select(
        db.workoutExercises,
      )..where((tbl) => tbl.sessionId.equals(session.id))).get();

      if (existingExercises.isNotEmpty) {
        final existingExerciseIds = existingExercises.map((e) => e.id).toList();

        await (db.delete(db.workoutSets)
              ..where((tbl) => tbl.workoutExerciseId.isIn(existingExerciseIds)))
            .go();

        await (db.delete(
          db.workoutExercises,
        )..where((tbl) => tbl.sessionId.equals(session.id))).go();
      }

      await (db.delete(
        db.workoutSessions,
      )..where((tbl) => tbl.id.equals(session.id))).go();

      await db
          .into(db.workoutSessions)
          .insert(
            WorkoutSessionsCompanion.insert(
              id: session.id,
              routineId: session.routineId,
              routineName: session.routineName,
              startedAt: session.startedAt,
              finishedAt: session.finishedAt,
              durationSeconds: session.durationSeconds,
              totalVolume: session.totalVolume,
              sessionTagsJson: Value(jsonEncode(session.sessionTags)),
              notes: Value(session.notes),
            ),
          );

      for (
        int exerciseIndex = 0;
        exerciseIndex < session.exercises.length;
        exerciseIndex++
      ) {
        final exercise = session.exercises[exerciseIndex];

        final insertedExercise = await db
            .into(db.workoutExercises)
            .insertReturning(
              WorkoutExercisesCompanion.insert(
                sessionId: session.id,
                exerciseId: exercise.exerciseId,
                exerciseName: exercise.exerciseName,
                muscleGroup: exercise.muscleGroup,
                sortOrder: exerciseIndex,
                tagsJson: Value(jsonEncode(exercise.tags)),
                isCustom: Value(exercise.isCustom),
              ),
            );

        for (final set in exercise.sets) {
          await db
              .into(db.workoutSets)
              .insert(
                WorkoutSetsCompanion.insert(
                  workoutExerciseId: insertedExercise.id,
                  setNumber: set.setNumber,
                  reps: set.reps,
                  weight: set.weight,
                  restSeconds: set.restSeconds,
                  isWarmup: Value(set.isWarmup),
                  createdAt: set.createdAt,
                ),
              );
        }
      }
    });
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    await db.transaction(() async {
      final existingExercises = await (db.select(
        db.workoutExercises,
      )..where((tbl) => tbl.sessionId.equals(sessionId))).get();

      if (existingExercises.isNotEmpty) {
        final existingExerciseIds = existingExercises.map((e) => e.id).toList();

        await (db.delete(db.workoutSets)
              ..where((tbl) => tbl.workoutExerciseId.isIn(existingExerciseIds)))
            .go();
      }

      await (db.delete(
        db.workoutExercises,
      )..where((tbl) => tbl.sessionId.equals(sessionId))).go();

      await (db.delete(
        db.workoutSessions,
      )..where((tbl) => tbl.id.equals(sessionId))).go();
    });
  }

  @override
  Future<void> clearAllSessions() async {
    await db.transaction(() async {
      await db.delete(db.workoutSets).go();
      await db.delete(db.workoutExercises).go();
      await db.delete(db.workoutSessions).go();
    });
  }


  @override
  Future<Map<String, ExercisePerformanceSnapshot>>
  getExerciseSnapshots() async {
    final sessions = await getAllSessions();
    final Map<String, _MutableExerciseSnapshot> snapshots = {};

    for (final session in sessions) {
      for (final exercise in session.exercises) {
        if (exercise.sets.isEmpty) continue;

        final workingSets = exercise.sets.where((set) => !set.isWarmup).toList();
        if (workingSets.isEmpty) continue;

        final snapshot = snapshots.putIfAbsent(
          exercise.exerciseId,
          () => _MutableExerciseSnapshot(),
        );

        for (final set in workingSets) {
          snapshot.registerSet(
            timestamp: set.createdAt,
            weight: set.weight,
            reps: set.reps,
          );
        }
      }
    }

    return snapshots.map((key, value) => MapEntry(key, value.toSnapshot()));
  }

  List<String> _decodeStringList(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is List) {
      return decoded.map((e) => e.toString()).toList();
    }
    return [];
  }
}

class _MutableExerciseSnapshot {
  DateTime? lastPerformedAt;
  double? lastWeight;
  int? lastReps;
  double? prWeight;
  int? prReps;
  int? bestReps;
  double? bestRepsWeight;
  double? bestSetVolume;
  double? bestSetVolumeWeight;
  int? bestSetVolumeReps;

  void registerSet({
    required DateTime timestamp,
    required double weight,
    required int reps,
  }) {
    if (lastPerformedAt == null || timestamp.isAfter(lastPerformedAt!)) {
      lastPerformedAt = timestamp;
      lastWeight = weight;
      lastReps = reps;
    }

    final shouldUpdateWeightPr =
        prWeight == null ||
        weight > prWeight! ||
        (weight == prWeight! && reps > (prReps ?? 0));

    if (shouldUpdateWeightPr) {
      prWeight = weight;
      prReps = reps;
    }

    final shouldUpdateRepsPr =
        bestReps == null ||
        reps > bestReps! ||
        (reps == bestReps! && weight > (bestRepsWeight ?? 0));

    if (shouldUpdateRepsPr) {
      bestReps = reps;
      bestRepsWeight = weight;
    }

    final setVolume = weight * reps;
    final shouldUpdateVolumePr =
        bestSetVolume == null ||
        setVolume > bestSetVolume! ||
        (setVolume == bestSetVolume! &&
            (weight > (bestSetVolumeWeight ?? 0) ||
                reps > (bestSetVolumeReps ?? 0)));

    if (shouldUpdateVolumePr) {
      bestSetVolume = setVolume;
      bestSetVolumeWeight = weight;
      bestSetVolumeReps = reps;
    }
  }

  ExercisePerformanceSnapshot toSnapshot() {
    return ExercisePerformanceSnapshot(
      lastPerformedAt: lastPerformedAt!,
      lastWeight: lastWeight!,
      lastReps: lastReps!,
      prWeight: prWeight!,
      prReps: prReps!,
      bestReps: bestReps!,
      bestRepsWeight: bestRepsWeight!,
      bestSetVolume: bestSetVolume!,
      bestSetVolumeWeight: bestSetVolumeWeight!,
      bestSetVolumeReps: bestSetVolumeReps!,
    );
  }
}
