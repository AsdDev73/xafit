import '../repositories/body_profile_repository.dart';
import '../repositories/body_progress_repository.dart';
import '../repositories/workout_repository.dart';

class AppRepositories {
  static final WorkoutRepository workouts = SharedPrefsWorkoutRepository();
  static final BodyProfileRepository bodyProfile =
      SharedPrefsBodyProfileRepository();
  static final BodyProgressRepository bodyProgress =
      SharedPrefsBodyProgressRepository();
}
