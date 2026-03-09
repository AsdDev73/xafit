import '../database/app_database.dart';
import '../repositories/body_profile_repository.dart';
import '../repositories/body_progress_repository.dart';
import '../repositories/drift_body_profile_repository.dart';
import '../repositories/drift_body_progress_repository.dart';
import '../repositories/drift_workout_repository.dart';
import '../repositories/workout_repository.dart';

class AppRepositories {
  static final AppDatabase database = AppDatabase();

  static final WorkoutRepository legacyWorkouts =
      SharedPrefsWorkoutRepository();
  static final WorkoutRepository driftWorkouts = DriftWorkoutRepository(
    database,
  );
  static final WorkoutRepository workouts = driftWorkouts;

  static final BodyProfileRepository legacyBodyProfile =
      SharedPrefsBodyProfileRepository();
  static final BodyProfileRepository driftBodyProfile =
      DriftBodyProfileRepository(database);
  static final BodyProfileRepository bodyProfile = driftBodyProfile;

  static final BodyProgressRepository legacyBodyProgress =
      SharedPrefsBodyProgressRepository();
  static final BodyProgressRepository driftBodyProgress =
      DriftBodyProgressRepository(database);
  static final BodyProgressRepository bodyProgress = driftBodyProgress;
}
