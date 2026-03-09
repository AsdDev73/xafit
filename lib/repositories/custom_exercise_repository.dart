import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/exercise.dart';

abstract class CustomExerciseRepository {
  Future<List<Exercise>> getAllCustomExercises();
  Future<List<Exercise>> getByMuscleGroup(String muscleGroup);
  Future<void> saveCustomExercise(Exercise exercise);
  Future<void> deleteCustomExercise(String exerciseId);
}

class SharedPrefsCustomExerciseRepository implements CustomExerciseRepository {
  static const String _key = 'xafit_custom_exercises';

  @override
  Future<List<Exercise>> getAllCustomExercises() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw) as List;

    final exercises = decoded.map((item) {
      final map = Map<String, dynamic>.from(item);
      return Exercise(
        id: map['id'] as String,
        name: map['name'] as String,
        muscleGroup: map['muscleGroup'] as String,
        tags: List<String>.from(map['tags'] as List),
        isCustom: true,
      );
    }).toList();

    exercises.sort((a, b) => a.name.compareTo(b.name));
    return exercises;
  }

  @override
  Future<List<Exercise>> getByMuscleGroup(String muscleGroup) async {
    final all = await getAllCustomExercises();
    return all
        .where((exercise) => exercise.muscleGroup == muscleGroup)
        .toList();
  }

  @override
  Future<void> saveCustomExercise(Exercise exercise) async {
    final exercises = await getAllCustomExercises();

    exercises.removeWhere((item) => item.id == exercise.id);
    exercises.add(
      Exercise(
        id: exercise.id,
        name: exercise.name,
        muscleGroup: exercise.muscleGroup,
        tags: exercise.tags,
        isCustom: true,
      ),
    );

    await _persist(exercises);
  }

  @override
  Future<void> deleteCustomExercise(String exerciseId) async {
    final exercises = await getAllCustomExercises();
    exercises.removeWhere((item) => item.id == exerciseId);
    await _persist(exercises);
  }

  Future<void> _persist(List<Exercise> exercises) async {
    final prefs = await SharedPreferences.getInstance();

    final raw = jsonEncode(
      exercises
          .map(
            (exercise) => {
              'id': exercise.id,
              'name': exercise.name,
              'muscleGroup': exercise.muscleGroup,
              'tags': exercise.tags,
            },
          )
          .toList(),
    );

    await prefs.setString(_key, raw);
  }
}
