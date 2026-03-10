import 'package:shared_preferences/shared_preferences.dart';

import '../models/body_profile.dart';
import '../repositories/body_profile_repository.dart';
import '../repositories/body_progress_repository.dart';
import '../repositories/custom_exercise_repository.dart';
import '../repositories/workout_repository.dart';

class DataMigrationService {
  static const String _migrationDoneKey = 'xafit_mobile_migration_v1_done';

  final WorkoutRepository legacyWorkoutRepository;
  final WorkoutRepository driftWorkoutRepository;

  final BodyProfileRepository legacyBodyProfileRepository;
  final BodyProfileRepository driftBodyProfileRepository;

  final BodyProgressRepository legacyBodyProgressRepository;
  final BodyProgressRepository driftBodyProgressRepository;

  final CustomExerciseRepository legacyCustomExerciseRepository;
  final CustomExerciseRepository driftCustomExerciseRepository;

  const DataMigrationService({
    required this.legacyWorkoutRepository,
    required this.driftWorkoutRepository,
    required this.legacyBodyProfileRepository,
    required this.driftBodyProfileRepository,
    required this.legacyBodyProgressRepository,
    required this.driftBodyProgressRepository,
    required this.legacyCustomExerciseRepository,
    required this.driftCustomExerciseRepository,
  });

  Future<void> migrateAllIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyMigrated = prefs.getBool(_migrationDoneKey) ?? false;

    if (alreadyMigrated) return;

    await _migrateWorkoutsIfNeeded();
    await _migrateBodyProfileIfNeeded();
    await _migrateBodyProgressIfNeeded();
    await _migrateCustomExercisesIfNeeded();

    await prefs.setBool(_migrationDoneKey, true);
  }

  Future<void> _migrateWorkoutsIfNeeded() async {
    final driftSessions = await driftWorkoutRepository.getAllSessions();
    if (driftSessions.isNotEmpty) return;

    final legacySessions = await legacyWorkoutRepository.getAllSessions();
    if (legacySessions.isEmpty) return;

    for (final session in legacySessions) {
      await driftWorkoutRepository.saveSession(session);
    }
  }

  Future<void> _migrateBodyProfileIfNeeded() async {
    final driftProfile = await driftBodyProfileRepository.getProfile();
    if (!_isEmptyProfile(driftProfile)) return;

    final legacyProfile = await legacyBodyProfileRepository.getProfile();
    if (_isEmptyProfile(legacyProfile)) return;

    await driftBodyProfileRepository.saveProfile(legacyProfile);
  }

  Future<void> _migrateBodyProgressIfNeeded() async {
    final driftEntries = await driftBodyProgressRepository.getEntries();
    if (driftEntries.isNotEmpty) return;

    final legacyEntries = await legacyBodyProgressRepository.getEntries();
    if (legacyEntries.isEmpty) return;

    for (final entry in legacyEntries) {
      await driftBodyProgressRepository.saveEntry(entry);
    }
  }

  Future<void> _migrateCustomExercisesIfNeeded() async {
    final driftExercises = await driftCustomExerciseRepository
        .getAllCustomExercises();
    if (driftExercises.isNotEmpty) return;

    final legacyExercises = await legacyCustomExerciseRepository
        .getAllCustomExercises();
    if (legacyExercises.isEmpty) return;

    for (final exercise in legacyExercises) {
      await driftCustomExerciseRepository.saveCustomExercise(exercise);
    }
  }

  bool _isEmptyProfile(BodyProfile profile) {
    return profile.alias == BodyProfile.empty.alias &&
        profile.goal == BodyProfile.empty.goal &&
        profile.heightCm == null &&
        profile.targetWeight == null &&
        profile.age == null;
  }
}
