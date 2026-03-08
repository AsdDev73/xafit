class WorkoutSession {
  final String id;
  final String routineId;
  final String routineName;
  final DateTime startedAt;
  final DateTime finishedAt;
  final int durationSeconds;
  final List<WorkoutExerciseRecord> exercises;
  final double totalVolume;
  final List<String> sessionTags;

  const WorkoutSession({
    required this.id,
    required this.routineId,
    required this.routineName,
    required this.startedAt,
    required this.finishedAt,
    required this.durationSeconds,
    required this.exercises,
    required this.totalVolume,
    required this.sessionTags,
  });

  int get totalExercises => exercises.length;

  int get totalSets {
    int total = 0;
    for (final exercise in exercises) {
      total += exercise.sets.length;
    }
    return total;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'routineId': routineId,
      'routineName': routineName,
      'startedAt': startedAt.toIso8601String(),
      'finishedAt': finishedAt.toIso8601String(),
      'durationSeconds': durationSeconds,
      'totalVolume': totalVolume,
      'sessionTags': sessionTags,
      'exercises': exercises.map((e) => e.toMap()).toList(),
    };
  }

  factory WorkoutSession.fromMap(Map<String, dynamic> map) {
    return WorkoutSession(
      id: map['id'],
      routineId: map['routineId'],
      routineName: map['routineName'],
      startedAt: DateTime.parse(map['startedAt']),
      finishedAt: DateTime.parse(map['finishedAt']),
      durationSeconds: map['durationSeconds'],
      totalVolume: (map['totalVolume'] as num).toDouble(),
      sessionTags: List<String>.from(map['sessionTags'] ?? const []),
      exercises: (map['exercises'] as List)
          .map(
            (e) => WorkoutExerciseRecord.fromMap(Map<String, dynamic>.from(e)),
          )
          .toList(),
    );
  }
}

class WorkoutExerciseRecord {
  final String exerciseId;
  final String exerciseName;
  final String muscleGroup;
  final List<String> tags;
  final bool isCustom;
  final List<WorkoutSetRecord> sets;

  const WorkoutExerciseRecord({
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    required this.tags,
    required this.isCustom,
    required this.sets,
  });

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'muscleGroup': muscleGroup,
      'tags': tags,
      'isCustom': isCustom,
      'sets': sets.map((s) => s.toMap()).toList(),
    };
  }

  factory WorkoutExerciseRecord.fromMap(Map<String, dynamic> map) {
    return WorkoutExerciseRecord(
      exerciseId: map['exerciseId'],
      exerciseName: map['exerciseName'],
      muscleGroup: map['muscleGroup'],
      tags: List<String>.from(map['tags']),
      isCustom: map['isCustom'] ?? false,
      sets: (map['sets'] as List)
          .map((s) => WorkoutSetRecord.fromMap(Map<String, dynamic>.from(s)))
          .toList(),
    );
  }
}

class WorkoutSetRecord {
  final int setNumber;
  final int reps;
  final double weight;
  final int restSeconds;
  final DateTime createdAt;

  const WorkoutSetRecord({
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

  factory WorkoutSetRecord.fromMap(Map<String, dynamic> map) {
    return WorkoutSetRecord(
      setNumber: map['setNumber'],
      reps: map['reps'],
      weight: (map['weight'] as num).toDouble(),
      restSeconds: map['restSeconds'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
