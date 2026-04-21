part of '../../screens/workout_screen.dart';

class _WorkoutExerciseEntry {
  final Exercise exercise;
  final List<_WorkoutSetEntry> sets;

  const _WorkoutExerciseEntry({required this.exercise, required this.sets});
}

class _WorkoutSetEntry {
  final int setNumber;
  final int reps;
  final double weight;
  final int restSeconds;
  final DateTime createdAt;
  final bool isWarmup;

  const _WorkoutSetEntry({
    required this.setNumber,
    required this.reps,
    required this.weight,
    required this.restSeconds,
    required this.createdAt,
    this.isWarmup = false,
  });

  _WorkoutSetEntry copyWith({
    int? setNumber,
    int? reps,
    double? weight,
    int? restSeconds,
    DateTime? createdAt,
    bool? isWarmup,
  }) {
    return _WorkoutSetEntry(
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      restSeconds: restSeconds ?? this.restSeconds,
      createdAt: createdAt ?? this.createdAt,
      isWarmup: isWarmup ?? this.isWarmup,
    );
  }
}

