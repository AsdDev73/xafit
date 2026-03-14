import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/exercise.dart';

class WorkoutDraft {
  final String title;
  final DateTime startedAt;
  final int currentRestSeconds;
  final bool hasStartedRestTracking;
  final List<WorkoutDraftExercise> exercises;

  const WorkoutDraft({
    required this.title,
    required this.startedAt,
    required this.currentRestSeconds,
    required this.hasStartedRestTracking,
    required this.exercises,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'startedAt': startedAt.toIso8601String(),
      'currentRestSeconds': currentRestSeconds,
      'hasStartedRestTracking': hasStartedRestTracking,
      'exercises': exercises.map((e) => e.toMap()).toList(),
    };
  }

  factory WorkoutDraft.fromMap(Map<String, dynamic> map) {
    return WorkoutDraft(
      title: (map['title'] ?? '').toString(),
      startedAt: DateTime.parse(map['startedAt'] as String),
      currentRestSeconds: (map['currentRestSeconds'] ?? 0) as int,
      hasStartedRestTracking: (map['hasStartedRestTracking'] ?? false) as bool,
      exercises: (map['exercises'] as List? ?? [])
          .map(
            (e) => WorkoutDraftExercise.fromMap(Map<String, dynamic>.from(e)),
          )
          .toList(),
    );
  }
}

class WorkoutDraftExercise {
  final Exercise exercise;
  final List<WorkoutDraftSet> sets;

  const WorkoutDraftExercise({required this.exercise, required this.sets});

  Map<String, dynamic> toMap() {
    return {
      'exercise': {
        'id': exercise.id,
        'name': exercise.name,
        'muscleGroup': exercise.muscleGroup,
        'tags': exercise.tags,
        'isCustom': exercise.isCustom,
      },
      'sets': sets.map((s) => s.toMap()).toList(),
    };
  }

  factory WorkoutDraftExercise.fromMap(Map<String, dynamic> map) {
    final exerciseMap = Map<String, dynamic>.from(map['exercise']);

    return WorkoutDraftExercise(
      exercise: Exercise(
        id: (exerciseMap['id'] ?? '').toString(),
        name: (exerciseMap['name'] ?? '').toString(),
        muscleGroup: (exerciseMap['muscleGroup'] ?? '').toString(),
        tags: (exerciseMap['tags'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
        isCustom: exerciseMap['isCustom'] == true,
      ),
      sets: (map['sets'] as List? ?? [])
          .map((s) => WorkoutDraftSet.fromMap(Map<String, dynamic>.from(s)))
          .toList(),
    );
  }
}

class WorkoutDraftSet {
  final int setNumber;
  final int reps;
  final double weight;
  final int restSeconds;
  final DateTime createdAt;

  const WorkoutDraftSet({
    required this.setNumber,
    required this.reps,
    required this.weight,
    required this.restSeconds,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'setNumber': setNumber,
      'reps': reps,
      'weight': weight,
      'restSeconds': restSeconds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory WorkoutDraftSet.fromMap(Map<String, dynamic> map) {
    return WorkoutDraftSet(
      setNumber: (map['setNumber'] ?? 1) as int,
      reps: (map['reps'] ?? 0) as int,
      weight: ((map['weight'] ?? 0) as num).toDouble(),
      restSeconds: (map['restSeconds'] ?? 0) as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

class WorkoutDraftService {
  static const String _draftKey = 'xafit_active_workout_draft';

  const WorkoutDraftService();

  Future<void> saveDraft(WorkoutDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftKey, jsonEncode(draft.toMap()));
  }

  Future<WorkoutDraft?> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);

    if (raw == null || raw.isEmpty) return null;

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;

    return WorkoutDraft.fromMap(decoded);
  }

  Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }
}
