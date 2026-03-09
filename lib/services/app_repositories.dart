import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../repositories/body_profile_repository.dart';
import '../repositories/body_progress_repository.dart';
import '../repositories/custom_exercise_repository.dart';
import '../repositories/drift_body_profile_repository.dart';
import '../repositories/drift_body_progress_repository.dart';
import '../repositories/drift_custom_exercise_repository.dart';
import '../repositories/drift_workout_repository.dart';
import '../repositories/workout_repository.dart';

class AppRepositories {
  static AppDatabase? _database;
  static AppDatabase get database => _database ??= AppDatabase();

  static final WorkoutRepository legacyWorkouts =
      SharedPrefsWorkoutRepository();
  static WorkoutRepository? _driftWorkouts;
  static WorkoutRepository get driftWorkouts =>
      _driftWorkouts ??= DriftWorkoutRepository(database);

  static WorkoutRepository get workouts =>
      kIsWeb ? legacyWorkouts : driftWorkouts;

  static final BodyProfileRepository legacyBodyProfile =
      SharedPrefsBodyProfileRepository();
  static BodyProfileRepository? _driftBodyProfile;
  static BodyProfileRepository get driftBodyProfile =>
      _driftBodyProfile ??= DriftBodyProfileRepository(database);

  static BodyProfileRepository get bodyProfile =>
      kIsWeb ? legacyBodyProfile : driftBodyProfile;

  static final BodyProgressRepository legacyBodyProgress =
      SharedPrefsBodyProgressRepository();
  static BodyProgressRepository? _driftBodyProgress;
  static BodyProgressRepository get driftBodyProgress =>
      _driftBodyProgress ??= DriftBodyProgressRepository(database);

  static BodyProgressRepository get bodyProgress =>
      kIsWeb ? legacyBodyProgress : driftBodyProgress;

  static final CustomExerciseRepository legacyCustomExercises =
      SharedPrefsCustomExerciseRepository();
  static CustomExerciseRepository? _driftCustomExercises;
  static CustomExerciseRepository get driftCustomExercises =>
      _driftCustomExercises ??= DriftCustomExerciseRepository(database);

  static CustomExerciseRepository get customExercises =>
      kIsWeb ? legacyCustomExercises : driftCustomExercises;
}
