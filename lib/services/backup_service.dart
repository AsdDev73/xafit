import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/exercise.dart';
import '../repositories/body_profile_repository.dart';
import '../repositories/body_progress_repository.dart';
import '../repositories/custom_exercise_repository.dart';
import '../repositories/workout_repository.dart';

class BackupService {
  final WorkoutRepository workoutRepository;
  final BodyProfileRepository bodyProfileRepository;
  final BodyProgressRepository bodyProgressRepository;
  final CustomExerciseRepository customExerciseRepository;

  const BackupService({
    required this.workoutRepository,
    required this.bodyProfileRepository,
    required this.bodyProgressRepository,
    required this.customExerciseRepository,
  });

  Future<Map<String, dynamic>> buildBackupMap() async {
    final profile = await bodyProfileRepository.getProfile();
    final progressEntries = await bodyProgressRepository.getEntries();
    final workoutSessions = await workoutRepository.getAllSessions();
    final customExercises = await customExerciseRepository
        .getAllCustomExercises();

    return {
      'format': 'xafit_backup',
      'version': 1,
      'app': 'XaFit',
      'exportedAt': DateTime.now().toIso8601String(),
      'data': {
        'bodyProfile': profile.toMap(),
        'bodyProgressEntries': progressEntries
            .map((entry) => entry.toMap())
            .toList(),
        'workoutSessions': workoutSessions
            .map((session) => session.toMap())
            .toList(),
        'customExercises': customExercises.map(_exerciseToMap).toList(),
      },
      'meta': {
        'counts': {
          'bodyProgressEntries': progressEntries.length,
          'workoutSessions': workoutSessions.length,
          'customExercises': customExercises.length,
        },
      },
    };
  }

  Future<String> buildBackupJson() async {
    final backupMap = await buildBackupMap();
    return const JsonEncoder.withIndent('  ').convert(backupMap);
  }

  Future<File> exportBackupToTempFile() async {
    final json = await buildBackupJson();
    final directory = await getTemporaryDirectory();
    final fileName =
        'xafit_backup_${_timestampForFileName(DateTime.now())}.json';
    final file = File('${directory.path}/$fileName');

    await file.writeAsString(json);

    return file;
  }

  Map<String, dynamic> _exerciseToMap(Exercise exercise) {
    return {
      'id': exercise.id,
      'name': exercise.name,
      'muscleGroup': exercise.muscleGroup,
      'tags': exercise.tags,
      'isCustom': exercise.isCustom,
    };
  }

  String _timestampForFileName(DateTime dateTime) {
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');

    return '${year}${month}${day}_${hour}${minute}${second}';
  }
}
