import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/body_profile.dart';
import '../models/body_progress_entry.dart';
import '../models/exercise.dart';
import '../models/workout_session.dart';
import '../repositories/body_profile_repository.dart';
import '../repositories/body_progress_repository.dart';
import '../repositories/custom_exercise_repository.dart';
import '../repositories/workout_repository.dart';

class BackupImportResult {
  final int importedSessions;
  final int importedProgressEntries;
  final int importedCustomExercises;
  final bool profileImported;

  const BackupImportResult({
    required this.importedSessions,
    required this.importedProgressEntries,
    required this.importedCustomExercises,
    required this.profileImported,
  });
}

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

  Future<BackupImportResult> importBackupFromFile(File file) async {
    final rawJson = await file.readAsString();
    final decoded = jsonDecode(rawJson);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'El archivo no contiene un objeto JSON válido',
      );
    }

    final format = decoded['format'];
    if (format != 'xafit_backup') {
      throw const FormatException('El archivo no es un backup válido de XaFit');
    }

    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException(
        'El backup no contiene la sección data válida',
      );
    }

    int importedSessions = 0;
    int importedProgressEntries = 0;
    int importedCustomExercises = 0;
    bool profileImported = false;

    final bodyProfileRaw = data['bodyProfile'];
    if (bodyProfileRaw is Map<String, dynamic>) {
      final profile = BodyProfile.fromMap(bodyProfileRaw);
      await bodyProfileRepository.saveProfile(profile);
      profileImported = true;
    }

    final progressEntriesRaw = data['bodyProgressEntries'];
    if (progressEntriesRaw is List) {
      for (final item in progressEntriesRaw) {
        if (item is Map<String, dynamic>) {
          final entry = BodyProgressEntry.fromMap(item);
          await bodyProgressRepository.saveEntry(entry);
          importedProgressEntries++;
        }
      }
    }

    final workoutSessionsRaw = data['workoutSessions'];
    if (workoutSessionsRaw is List) {
      for (final item in workoutSessionsRaw) {
        if (item is Map<String, dynamic>) {
          final session = WorkoutSession.fromMap(item);
          await workoutRepository.saveSession(session);
          importedSessions++;
        }
      }
    }

    final customExercisesRaw = data['customExercises'];
    if (customExercisesRaw is List) {
      for (final item in customExercisesRaw) {
        if (item is Map<String, dynamic>) {
          final exercise = _exerciseFromMap(item);
          await customExerciseRepository.saveCustomExercise(exercise);
          importedCustomExercises++;
        }
      }
    }

    return BackupImportResult(
      importedSessions: importedSessions,
      importedProgressEntries: importedProgressEntries,
      importedCustomExercises: importedCustomExercises,
      profileImported: profileImported,
    );
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

  Exercise _exerciseFromMap(Map<String, dynamic> map) {
    return Exercise(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      muscleGroup: (map['muscleGroup'] ?? '').toString(),
      tags: (map['tags'] is List)
          ? (map['tags'] as List).map((e) => e.toString()).toList()
          : <String>[],
      isCustom: map['isCustom'] == true,
    );
  }

  String _timestampForFileName(DateTime dateTime) {
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');

    return '$year$month${day}_$hour$minute$second';
  }
}
