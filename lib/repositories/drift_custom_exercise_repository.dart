import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/exercise.dart';
import 'custom_exercise_repository.dart';

class DriftCustomExerciseRepository implements CustomExerciseRepository {
  final AppDatabase db;

  DriftCustomExerciseRepository(this.db);

  @override
  Future<List<Exercise>> getAllCustomExercises() async {
    final rows = await (db.select(
      db.customExercises,
    )..orderBy([(tbl) => OrderingTerm.asc(tbl.name)])).get();

    return rows
        .map(
          (row) => Exercise(
            id: row.id,
            name: row.name,
            muscleGroup: row.muscleGroup,
            tags: _decodeStringList(row.tagsJson),
            isCustom: true,
          ),
        )
        .toList();
  }

  @override
  Future<List<Exercise>> getByMuscleGroup(String muscleGroup) async {
    final rows =
        await (db.select(db.customExercises)
              ..where((tbl) => tbl.muscleGroup.equals(muscleGroup))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
            .get();

    return rows
        .map(
          (row) => Exercise(
            id: row.id,
            name: row.name,
            muscleGroup: row.muscleGroup,
            tags: _decodeStringList(row.tagsJson),
            isCustom: true,
          ),
        )
        .toList();
  }

  @override
  Future<void> saveCustomExercise(Exercise exercise) async {
    final existing = await (db.select(
      db.customExercises,
    )..where((tbl) => tbl.id.equals(exercise.id))).getSingleOrNull();

    await db
        .into(db.customExercises)
        .insertOnConflictUpdate(
          CustomExercisesCompanion.insert(
            id: exercise.id,
            name: exercise.name,
            muscleGroup: exercise.muscleGroup,
            tagsJson: Value(jsonEncode(exercise.tags)),
            createdAt: existing?.createdAt ?? DateTime.now(),
          ),
        );
  }

  @override
  Future<void> deleteCustomExercise(String exerciseId) async {
    await (db.delete(
      db.customExercises,
    )..where((tbl) => tbl.id.equals(exerciseId))).go();
  }

  List<String> _decodeStringList(String rawJson) {
    final decoded = jsonDecode(rawJson);

    if (decoded is List) {
      return decoded.map((e) => e.toString()).toList();
    }

    return [];
  }
}
