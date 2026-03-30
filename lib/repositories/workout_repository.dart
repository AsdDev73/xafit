import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/workout_session.dart';

class ExercisePerformanceSnapshot {
  final DateTime lastPerformedAt;
  final double lastWeight;
  final int lastReps;
  final double prWeight;
  final int prReps;
  final int bestReps;
  final double bestRepsWeight;
  final double bestSetVolume;
  final double bestSetVolumeWeight;
  final int bestSetVolumeReps;

  const ExercisePerformanceSnapshot({
    required this.lastPerformedAt,
    required this.lastWeight,
    required this.lastReps,
    required this.prWeight,
    required this.prReps,
    required this.bestReps,
    required this.bestRepsWeight,
    required this.bestSetVolume,
    required this.bestSetVolumeWeight,
    required this.bestSetVolumeReps,
  });
}

abstract class WorkoutRepository {
  Future<List<WorkoutSession>> getAllSessions();
  Future<void> saveSession(WorkoutSession session);
  Future<void> deleteSession(String sessionId);
  Future<void> clearAllSessions();
  Future<Map<String, ExercisePerformanceSnapshot>> getExerciseSnapshots();
}

class SharedPrefsWorkoutRepository implements WorkoutRepository {
  static const String _sessionsKey = 'xafit_workout_sessions';

  @override
  Future<List<WorkoutSession>> getAllSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionsKey);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw) as List;

    final sessions = decoded
        .map((item) => WorkoutSession.fromMap(Map<String, dynamic>.from(item)))
        .toList();

    sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return sessions;
  }

  @override
  Future<void> saveSession(WorkoutSession session) async {
    final sessions = await getAllSessions();

    sessions.removeWhere((item) => item.id == session.id);
    sessions.insert(0, session);

    await _persistSessions(sessions);
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    final sessions = await getAllSessions();
    sessions.removeWhere((item) => item.id == sessionId);
    await _persistSessions(sessions);
  }

  @override
  Future<void> clearAllSessions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionsKey);
  }

  @override
  Future<Map<String, ExercisePerformanceSnapshot>> getExerciseSnapshots() async {
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

  Future<void> _persistSessions(List<WorkoutSession> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(sessions.map((session) => session.toMap()).toList());
    await prefs.setString(_sessionsKey, raw);
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
