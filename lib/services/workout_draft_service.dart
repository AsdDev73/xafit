import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/exercise.dart';

/// Borrador persistente del entrenamiento en curso.
///
/// Además de lo que ya guardabas antes, aquí añadimos:
/// - [restStartedAt]: fecha real en la que empezó el descanso actual.
///   Esto permite reconstruir el contador correctamente si la app se cierra.
/// - [liveActivityId]: id devuelto por iOS para poder actualizar o cerrar la
///   Live Activity asociada al entreno.
class WorkoutDraft {
  final String title;
  final DateTime startedAt;
  final int currentRestSeconds;
  final bool hasStartedRestTracking;
  final DateTime? restStartedAt;
  final String? liveActivityId;
  final List<WorkoutDraftExercise> exercises;

  const WorkoutDraft({
    required this.title,
    required this.startedAt,
    required this.currentRestSeconds,
    required this.hasStartedRestTracking,
    required this.exercises,
    this.restStartedAt,
    this.liveActivityId,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'startedAt': startedAt.toIso8601String(),
      'currentRestSeconds': currentRestSeconds,
      'hasStartedRestTracking': hasStartedRestTracking,
      'restStartedAt': restStartedAt?.toIso8601String(),
      'liveActivityId': liveActivityId,
      'exercises': exercises.map((e) => e.toMap()).toList(),
    };
  }

  factory WorkoutDraft.fromMap(Map<String, dynamic> map) {
    final rawRestStartedAt = map['restStartedAt']?.toString();

    return WorkoutDraft(
      title: (map['title'] ?? '').toString(),
      startedAt: DateTime.parse(map['startedAt'] as String),
      currentRestSeconds: ((map['currentRestSeconds'] ?? 0) as num).toInt(),
      hasStartedRestTracking: (map['hasStartedRestTracking'] ?? false) as bool,
      restStartedAt: rawRestStartedAt == null || rawRestStartedAt.isEmpty
          ? null
          : DateTime.tryParse(rawRestStartedAt),
      liveActivityId: map['liveActivityId']?.toString(),
      exercises: (map['exercises'] as List? ?? [])
          .map(
            (e) => WorkoutDraftExercise.fromMap(Map<String, dynamic>.from(e)),
          )
          .toList(),
    );
  }
}

/// Cada ejercicio guardado dentro del borrador.
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

/// Serie individual guardada dentro del borrador.
class WorkoutDraftSet {
  final int setNumber;
  final int reps;
  final double weight;
  final int restSeconds;
  final DateTime createdAt;
  final bool isWarmup;

  const WorkoutDraftSet({
    required this.setNumber,
    required this.reps,
    required this.weight,
    required this.restSeconds,
    required this.createdAt,
    this.isWarmup = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'setNumber': setNumber,
      'reps': reps,
      'weight': weight,
      'restSeconds': restSeconds,
      'createdAt': createdAt.toIso8601String(),
      'isWarmup': isWarmup,
    };
  }

  factory WorkoutDraftSet.fromMap(Map<String, dynamic> map) {
    return WorkoutDraftSet(
      setNumber: ((map['setNumber'] ?? 1) as num).toInt(),
      reps: ((map['reps'] ?? 0) as num).toInt(),
      weight: ((map['weight'] ?? 0) as num).toDouble(),
      restSeconds: ((map['restSeconds'] ?? 0) as num).toInt(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      isWarmup: map['isWarmup'] == true,
    );
  }
}

/// Servicio mínimo de persistencia del borrador activo.
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
