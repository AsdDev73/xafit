import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../models/workout_session.dart';
import '../repositories/custom_exercise_repository.dart';
import '../repositories/workout_repository.dart';
import '../services/app_repositories.dart';
import '../services/favorite_exercises_service.dart';
import '../services/workout_draft_service.dart';
import '../services/workout_live_activity_service.dart';
import '../widgets/workout/set_editor_sheet.dart';
import '../widgets/workout/workout_exercise_card.dart';
import '../widgets/workout/workout_header_panel.dart';

part '../widgets/workout/workout_finish_dialog.dart';
part '../widgets/workout/workout_session_models.dart';
part '../widgets/workout/workout_exercise_picker_sheet.dart';

class WorkoutScreen extends StatefulWidget {
  final String title;
  final List<Exercise> availableExercises;

  const WorkoutScreen({
    super.key,
    required this.title,
    required this.availableExercises,
  });

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  // Colores base de la pantalla.
  static const Color _panelSoftColor = Color(0xFF1C2330);

  // Repositorios principales.
  final WorkoutRepository _workoutRepository = AppRepositories.workouts;
  final CustomExerciseRepository _customExerciseRepository =
      AppRepositories.customExercises;
  final WorkoutDraftService _workoutDraftService = const WorkoutDraftService();
  final WorkoutLiveActivityService _workoutLiveActivityService =
      WorkoutLiveActivityService.instance;

  // Estado del entrenamiento actual.
  final List<_WorkoutExerciseEntry> _selectedExercises = [];
  final List<Exercise> _customExercises = [];

  // Snapshots del rendimiento histórico por ejercicio.
  Map<String, ExercisePerformanceSnapshot> _exerciseSnapshots = {};

  late DateTime _startedAt;
  DateTime? _restStartedAt;
  Timer? _workoutTimer;
  Timer? _restTimer;

  int _elapsedSeconds = 0;
  int _currentRestSeconds = 0;
  bool _isSaving = false;
  bool _hasStartedRestTracking = false;
  String? _liveActivityId;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();

    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds = DateTime.now().difference(_startedAt).inSeconds;
      });
    });

    _loadExerciseSnapshots();
    _loadCustomExercises();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreDraftIfNeeded();
    });
  }

  @override
  void dispose() {
    _workoutTimer?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadExerciseSnapshots() async {
    final snapshots = await _workoutRepository.getExerciseSnapshots();

    if (!mounted) return;

    setState(() {
      _exerciseSnapshots = snapshots;
    });
  }

  Future<void> _loadCustomExercises() async {
    final customExercises =
        await _customExerciseRepository.getAllCustomExercises();

    if (!mounted) return;

    setState(() {
      _customExercises
        ..clear()
        ..addAll(customExercises);
    });
  }

  // Mezcla ejercicios base + personalizados evitando duplicados por id.
  List<Exercise> get _allAvailableExercises {
    final Map<String, Exercise> byId = {};

    for (final exercise in widget.availableExercises) {
      byId[exercise.id] = exercise;
    }

    for (final exercise in _customExercises) {
      byId[exercise.id] = exercise;
    }

    return byId.values.toList();
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String _formatWeight(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  String _formatCompactVolume(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)} t';
    }
    return '${_formatWeight(value)} kg';
  }

  String _formatRestLabel(int seconds) {
    if (seconds < 60) return '${seconds}s';

    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    if (remainingSeconds == 0) {
      return '${minutes}m';
    }

    return '${minutes}m ${remainingSeconds}s';
  }

  String _normalizeText(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
  }

  // Convierte el grupo muscular a uno de los tags principales de sesión.
  String? _normalizeMuscleGroupToSessionTag(String muscleGroup) {
    final normalized = _normalizeText(muscleGroup.trim());

    if (normalized.contains('pecho')) return 'pecho';
    if (normalized.contains('espalda')) return 'espalda';
    if (normalized.contains('hombro')) return 'hombro';
    if (normalized.contains('biceps')) return 'biceps';
    if (normalized.contains('triceps')) return 'triceps';

    if (normalized.contains('pierna') ||
        normalized.contains('cuadriceps') ||
        normalized.contains('femoral') ||
        normalized.contains('gluteo') ||
        normalized.contains('gemelo')) {
      return 'pierna';
    }

    if (normalized.contains('abdomen') ||
        normalized.contains('abs') ||
        normalized.contains('core')) {
      return 'abdomen';
    }

    return null;
  }

  List<String> _buildSessionTags(List<_WorkoutExerciseEntry> entries) {
    final tags = <String>{};

    for (final entry in entries) {
      final tag = _normalizeMuscleGroupToSessionTag(entry.exercise.muscleGroup);
      if (tag != null) {
        tags.add(tag);
      }
    }

    const order = [
      'pecho',
      'espalda',
      'hombro',
      'biceps',
      'triceps',
      'pierna',
      'abdomen',
    ];

    final sorted = tags.toList()
      ..sort((a, b) {
        final indexA = order.indexOf(a);
        final indexB = order.indexOf(b);

        if (indexA == -1 && indexB == -1) return a.compareTo(b);
        if (indexA == -1) return 1;
        if (indexB == -1) return -1;
        return indexA.compareTo(indexB);
      });

    return sorted;
  }

  ExercisePerformanceSnapshot? _statsForExercise(Exercise exercise) {
    return _exerciseSnapshots[exercise.id];
  }

  int get _totalSets {
    int total = 0;
    for (final exercise in _selectedExercises) {
      total += exercise.sets.length;
    }
    return total;
  }

  int get _totalWarmupSets {
    int total = 0;
    for (final exercise in _selectedExercises) {
      total += exercise.sets.where((set) => set.isWarmup).length;
    }
    return total;
  }

  int get _totalWorkingSets => _totalSets - _totalWarmupSets;

  double get _totalVolume {
    double total = 0;
    for (final exercise in _selectedExercises) {
      for (final set in exercise.sets) {
        total += set.weight * set.reps;
      }
    }
    return total;
  }

  double _exerciseVolume(_WorkoutExerciseEntry entry) {
    return entry.sets.fold<double>(
      0,
      (total, set) => total + (set.weight * set.reps),
    );
  }

  int _exerciseWarmupCount(_WorkoutExerciseEntry entry) {
    return entry.sets.where((set) => set.isWarmup).length;
  }

  int _exerciseWorkingCount(_WorkoutExerciseEntry entry) {
    return entry.sets.length - _exerciseWarmupCount(entry);
  }

  // Snackbar segura para evitar errores al cerrar diálogos/sheets.
  void _showMessage(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    });
  }

  Future<_FinishWorkoutDecision?> _showFinishWorkoutDialog() {
    return showDialog<_FinishWorkoutDecision>(
      context: context,
      builder: (dialogContext) => const _FinishWorkoutDialog(),
    );
  }

  List<_WorkoutPersonalRecordAchievement> _detectPersonalRecords(
    List<_WorkoutExerciseEntry> validExercises,
  ) {
    final Map<String, _WorkoutPersonalRecordAchievement> achievementsByKey = {};

    for (final entry in validExercises) {
      final workingSets = entry.sets.where((set) => !set.isWarmup).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      if (workingSets.isEmpty) continue;

      final snapshot = _exerciseSnapshots[entry.exercise.id];
      double? bestWeight = snapshot?.prWeight;
      int? bestWeightReps = snapshot?.prReps;
      int? bestReps = snapshot?.bestReps;
      double? bestRepsWeight = snapshot?.bestRepsWeight;
      double? bestVolume = snapshot?.bestSetVolume;
      double? bestVolumeWeight = snapshot?.bestSetVolumeWeight;
      int? bestVolumeReps = snapshot?.bestSetVolumeReps;

      for (final set in workingSets) {
        final setVolume = set.weight * set.reps;

        final isWeightPr = bestWeight == null ||
            set.weight > bestWeight ||
            (set.weight == bestWeight && set.reps > (bestWeightReps ?? 0));

        final isRepsPr = bestReps == null ||
            set.reps > bestReps ||
            (set.reps == bestReps && set.weight > (bestRepsWeight ?? 0));

        final isVolumePr = bestVolume == null ||
            setVolume > bestVolume ||
            (setVolume == bestVolume &&
                (set.weight > (bestVolumeWeight ?? 0) ||
                    set.reps > (bestVolumeReps ?? 0)));

        if (isWeightPr) {
          achievementsByKey[
                  '${entry.exercise.id}_${_WorkoutPersonalRecordType.weight.name}'] =
              _WorkoutPersonalRecordAchievement(
            exerciseId: entry.exercise.id,
            exerciseName: entry.exercise.name,
            type: _WorkoutPersonalRecordType.weight,
            weight: set.weight,
            reps: set.reps,
          );
          bestWeight = set.weight;
          bestWeightReps = set.reps;
        }

        if (isRepsPr) {
          achievementsByKey[
                  '${entry.exercise.id}_${_WorkoutPersonalRecordType.reps.name}'] =
              _WorkoutPersonalRecordAchievement(
            exerciseId: entry.exercise.id,
            exerciseName: entry.exercise.name,
            type: _WorkoutPersonalRecordType.reps,
            weight: set.weight,
            reps: set.reps,
          );
          bestReps = set.reps;
          bestRepsWeight = set.weight;
        }

        if (isVolumePr) {
          achievementsByKey[
                  '${entry.exercise.id}_${_WorkoutPersonalRecordType.volume.name}'] =
              _WorkoutPersonalRecordAchievement(
            exerciseId: entry.exercise.id,
            exerciseName: entry.exercise.name,
            type: _WorkoutPersonalRecordType.volume,
            weight: set.weight,
            reps: set.reps,
          );
          bestVolume = setVolume;
          bestVolumeWeight = set.weight;
          bestVolumeReps = set.reps;
        }
      }
    }

    final achievements = achievementsByKey.values.toList()
      ..sort((a, b) {
        final exerciseCompare = a.exerciseName.compareTo(b.exerciseName);
        if (exerciseCompare != 0) return exerciseCompare;
        return a.type.index.compareTo(b.type.index);
      });

    return achievements;
  }

  Future<void> _showPersonalRecordsDialog(
    List<_WorkoutPersonalRecordAchievement> achievements,
  ) async {
    if (!mounted || achievements.isEmpty) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('¡Nuevos PRs!'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievements.length == 1
                        ? 'Has batido una marca personal en esta sesión.'
                        : 'Has batido ${achievements.length} marcas personales en esta sesión.',
                  ),
                  const SizedBox(height: 16),
                  ...achievements.map(
                    (achievement) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PersonalRecordDialogTile(
                        achievement: achievement,
                        formatWeight: _formatWeight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Seguir'),
            ),
          ],
        );
      },
    );
  }

  String _liveActivityCustomId() {
    return 'xafit_workout_${_startedAt.microsecondsSinceEpoch}';
  }

  String _liveActivityCurrentExerciseName() {
    if (_selectedExercises.isEmpty) {
      return 'Sin ejercicio';
    }

    _WorkoutExerciseEntry? latestEntry;
    DateTime? latestSetDate;

    for (final entry in _selectedExercises) {
      if (entry.sets.isEmpty) continue;

      final entryLatestDate = entry.sets.last.createdAt;
      if (latestSetDate == null || entryLatestDate.isAfter(latestSetDate)) {
        latestSetDate = entryLatestDate;
        latestEntry = entry;
      }
    }

    return latestEntry?.exercise.name ?? _selectedExercises.last.exercise.name;
  }

  DateTime? _restStartedAtFromDraft(WorkoutDraft draft) {
    if (!draft.hasStartedRestTracking) return null;

    if (draft.restStartedAt != null) {
      return draft.restStartedAt;
    }

    if (draft.currentRestSeconds <= 0) return null;

    return DateTime.now().subtract(
      Duration(seconds: draft.currentRestSeconds),
    );
  }

  Future<String?> _syncLiveActivity() async {
    if (kIsWeb || _selectedExercises.isEmpty) {
      return _liveActivityId;
    }

    final payload = WorkoutLiveActivityPayload(
      customId: _liveActivityCustomId(),
      title: widget.title,
      workoutStartedAt: _startedAt,
      isResting: _hasStartedRestTracking && _restStartedAt != null,
      restStartedAt: (_hasStartedRestTracking && _restStartedAt != null)
          ? _restStartedAt
          : null,
      currentExerciseName: _liveActivityCurrentExerciseName(),
      exercisesCount: _selectedExercises.length,
      setsCount: _totalSets,
    );

    final updatedActivityId = await _workoutLiveActivityService.startOrUpdate(
      payload: payload,
      currentActivityId: _liveActivityId,
    );

    if (updatedActivityId != null && updatedActivityId.isNotEmpty) {
      _liveActivityId = updatedActivityId;
    }

    return _liveActivityId;
  }

  Future<void> _endLiveActivity() async {
    final activityId = _liveActivityId;
    _liveActivityId = null;
    await _workoutLiveActivityService.end(activityId);
  }

  // Reinicia el contador de descanso cada vez que se guarda/duplica una serie.
  void _restartRestStopwatch() {
    _restTimer?.cancel();

    _restStartedAt = DateTime.now();
    _currentRestSeconds = 0;
    _hasStartedRestTracking = true;

    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _restStartedAt == null) return;

      setState(() {
        _currentRestSeconds =
            DateTime.now().difference(_restStartedAt!).inSeconds;
      });
    });

    unawaited(_syncLiveActivity());
  }

  Future<void> _saveDraftSilently() async {
    if (_selectedExercises.isEmpty) {
      await _workoutDraftService.clearDraft();
      await _endLiveActivity();
      return;
    }

    final syncedActivityId = await _syncLiveActivity();

    final draft = WorkoutDraft(
      title: widget.title,
      startedAt: _startedAt,
      currentRestSeconds: _currentRestSeconds,
      hasStartedRestTracking: _hasStartedRestTracking,
      restStartedAt: _restStartedAt,
      liveActivityId: syncedActivityId,
      exercises: _selectedExercises.map((entry) {
        return WorkoutDraftExercise(
          exercise: entry.exercise,
          sets: entry.sets.map((set) {
            return WorkoutDraftSet(
              setNumber: set.setNumber,
              reps: set.reps,
              weight: set.weight,
              restSeconds: set.restSeconds,
              createdAt: set.createdAt,
              isWarmup: set.isWarmup,
            );
          }).toList(),
        );
      }).toList(),
    );

    await _workoutDraftService.saveDraft(draft);
  }

  void _resumeRestStopwatch() {
    _restTimer?.cancel();

    if (!_hasStartedRestTracking) return;

    _restStartedAt ??= DateTime.now().subtract(
      Duration(seconds: _currentRestSeconds),
    );

    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _restStartedAt == null) return;

      setState(() {
        _currentRestSeconds =
            DateTime.now().difference(_restStartedAt!).inSeconds;
      });
    });
  }

  Future<void> _restoreDraftIfNeeded() async {
    final draft = await _workoutDraftService.loadDraft();

    if (!mounted || draft == null) return;

    // Solo restauramos si pertenece a esta misma pantalla/título.
    if (draft.title != widget.title) return;
    if (draft.exercises.isEmpty) return;

    final shouldRestore = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Recuperar entrenamiento'),
              content: const Text(
                'Hay un entrenamiento en curso sin guardar. ¿Quieres recuperarlo?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Descartar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Recuperar'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!mounted) return;

    if (!shouldRestore) {
      _liveActivityId = draft.liveActivityId;
      await _workoutDraftService.clearDraft();
      await _endLiveActivity();
      return;
    }

    final restoredRestStartedAt = _restStartedAtFromDraft(draft);
    final restoredRestSeconds = restoredRestStartedAt == null
        ? draft.currentRestSeconds
        : DateTime.now().difference(restoredRestStartedAt).inSeconds;

    setState(() {
      _startedAt = draft.startedAt;
      _elapsedSeconds = DateTime.now().difference(_startedAt).inSeconds;
      _currentRestSeconds = restoredRestSeconds < 0 ? 0 : restoredRestSeconds;
      _hasStartedRestTracking = draft.hasStartedRestTracking;
      _restStartedAt = restoredRestStartedAt;
      _liveActivityId = draft.liveActivityId;

      _selectedExercises
        ..clear()
        ..addAll(
          draft.exercises.map(
            (draftExercise) => _WorkoutExerciseEntry(
              exercise: draftExercise.exercise,
              sets: draftExercise.sets.map((draftSet) {
                return _WorkoutSetEntry(
                  setNumber: draftSet.setNumber,
                  reps: draftSet.reps,
                  weight: draftSet.weight,
                  restSeconds: draftSet.restSeconds,
                  createdAt: draftSet.createdAt,
                  isWarmup: draftSet.isWarmup,
                );
              }).toList(),
            ),
          ),
        );
    });

    _resumeRestStopwatch();
    await _syncLiveActivity();
    _showMessage('Entrenamiento recuperado');
  }

  bool get _hasUnsavedChanges => _selectedExercises.isNotEmpty;

  // Pregunta antes de salir si hay ejercicios añadidos sin guardar.
  Future<bool> _confirmDiscardWorkout() async {
    if (_isSaving) return false;
    if (!_hasUnsavedChanges) return true;

    final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Salir del entrenamiento'),
              content: const Text(
                'Tienes cambios sin guardar. Si sales ahora, perderás este entrenamiento.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Seguir aquí'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Salir sin guardar'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (shouldLeave) {
      await _workoutDraftService.clearDraft();
      await _endLiveActivity();
    }

    return shouldLeave;
  }

  // Reordena ejercicios en la lista actual.
  Future<void> _reorderExercises(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    if (oldIndex == newIndex) return;

    setState(() {
      final item = _selectedExercises.removeAt(oldIndex);
      _selectedExercises.insert(newIndex, item);
    });

    await _saveDraftSilently();
  }

  Future<void> _showExercisePicker() async {
    final selectedExercise = await showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151922),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _ExercisePickerSheet(
        exercises: _allAvailableExercises,
        alreadySelectedIds:
            _selectedExercises.map((e) => e.exercise.id).toSet(),
      ),
    );

    if (selectedExercise == null) return;

    setState(() {
      _selectedExercises.add(
        _WorkoutExerciseEntry(exercise: selectedExercise, sets: []),
      );
    });

    await _saveDraftSilently();
    _showMessage('${selectedExercise.name} añadido');
  }

  // Editor de serie: el bottom sheet devuelve el resultado
  // y la pantalla padre actualiza el estado después.
  Future<void> _showSetEditorSheet(
    _WorkoutExerciseEntry entry, {
    int? setIndex,
  }) async {
    final isEditing = setIndex != null;
    final existingSet = isEditing ? entry.sets[setIndex] : null;
    final previousSet =
        !isEditing && entry.sets.isNotEmpty ? entry.sets.last : null;
    final snapshot = _statsForExercise(entry.exercise);

    final result = await showModalBottomSheet<SetEditorResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151922),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return SetEditorSheet(
          isEditing: isEditing,
          exerciseName: entry.exercise.name,
          panelColor: _panelSoftColor,
          initialWeightText: existingSet != null
              ? _formatWeight(existingSet.weight)
              : previousSet != null
                  ? _formatWeight(previousSet.weight)
                  : snapshot != null
                      ? _formatWeight(snapshot.lastWeight)
                      : '',
          initialRepsText: existingSet != null
              ? existingSet.reps.toString()
              : previousSet != null
                  ? previousSet.reps.toString()
                  : snapshot != null
                      ? snapshot.lastReps.toString()
                      : '',
          previousSetWeight: previousSet?.weight,
          previousSetReps: previousSet?.reps,
          previousSetIsWarmup: previousSet?.isWarmup ?? false,
          initialIsWarmup: existingSet?.isWarmup ?? false,
          lastWeight: snapshot?.lastWeight,
          lastReps: snapshot?.lastReps,
          prWeight: snapshot?.prWeight,
          prReps: snapshot?.prReps,
          restLabel: isEditing
              ? _formatRestLabel(existingSet!.restSeconds)
              : _hasStartedRestTracking
                  ? _formatRestLabel(_currentRestSeconds)
                  : '0s',
          formatWeight: _formatWeight,
        );
      },
    );

    if (result == null) return;
    if (!mounted) return;

    setState(() {
      if (isEditing) {
        entry.sets[setIndex] = _WorkoutSetEntry(
          setNumber: existingSet!.setNumber,
          reps: result.reps,
          weight: result.weight,
          restSeconds: existingSet.restSeconds,
          createdAt: existingSet.createdAt,
          isWarmup: result.isWarmup,
        );
      } else {
        entry.sets.add(
          _WorkoutSetEntry(
            setNumber: entry.sets.length + 1,
            reps: result.reps,
            weight: result.weight,
            restSeconds: _hasStartedRestTracking ? _currentRestSeconds : 0,
            createdAt: DateTime.now(),
            isWarmup: result.isWarmup,
          ),
        );
      }
    });

    if (!isEditing) {
      _restartRestStopwatch();
    }

    await _saveDraftSilently();
    _showMessage(isEditing ? 'Serie actualizada' : 'Serie guardada');
  }

  Future<void> _deleteSet(_WorkoutExerciseEntry entry, int setIndex) async {
    setState(() {
      entry.sets.removeAt(setIndex);

      for (int i = 0; i < entry.sets.length; i++) {
        entry.sets[i] = entry.sets[i].copyWith(setNumber: i + 1);
      }
    });

    await _saveDraftSilently();
    _showMessage('Serie eliminada');
  }

  Future<void> _duplicateLastSet(_WorkoutExerciseEntry entry) async {
    if (entry.sets.isEmpty) return;

    final lastSet = entry.sets.last;

    setState(() {
      entry.sets.add(
        _WorkoutSetEntry(
          setNumber: entry.sets.length + 1,
          reps: lastSet.reps,
          weight: lastSet.weight,
          restSeconds: _hasStartedRestTracking ? _currentRestSeconds : 0,
          createdAt: DateTime.now(),
          isWarmup: lastSet.isWarmup,
        ),
      );
    });

    _restartRestStopwatch();
    await _saveDraftSilently();
    _showMessage('Serie duplicada');
  }

  Future<void> _removeExercise(_WorkoutExerciseEntry entry) async {
    setState(() {
      _selectedExercises.remove(entry);
    });

    await _saveDraftSilently();
    _showMessage('${entry.exercise.name} eliminado del entreno');
  }

  Future<void> _finishWorkout() async {
    if (_selectedExercises.isEmpty) {
      _showMessage('Añade al menos un ejercicio');
      return;
    }

    final validExercises = _selectedExercises
        .where((exercise) => exercise.sets.isNotEmpty)
        .toList();

    if (validExercises.isEmpty) {
      _showMessage('Añade al menos una serie');
      return;
    }

    final finishDecision = await _showFinishWorkoutDialog();
    if (!mounted || finishDecision == null) return;

    final personalRecords = _detectPersonalRecords(validExercises);

    setState(() {
      _isSaving = true;
    });

    try {
      final completedAt = DateTime.now();

      final session = WorkoutSession(
        id: completedAt.microsecondsSinceEpoch.toString(),
        routineId: 'free_workout',
        routineName: widget.title,
        startedAt: _startedAt,
        finishedAt: completedAt,
        durationSeconds: completedAt.difference(_startedAt).inSeconds,
        totalVolume: validExercises.fold<double>(
          0,
          (total, entry) =>
              total +
              entry.sets.fold<double>(
                0,
                (exerciseTotal, set) => exerciseTotal + (set.weight * set.reps),
              ),
        ),
        sessionTags: _buildSessionTags(validExercises),
        notes: finishDecision.notes,
        exercises: validExercises.map((entry) {
          return WorkoutExerciseRecord(
            exerciseId: entry.exercise.id,
            exerciseName: entry.exercise.name,
            muscleGroup: entry.exercise.muscleGroup,
            tags: entry.exercise.tags,
            isCustom: entry.exercise.isCustom,
            sets: entry.sets.map((set) {
              return WorkoutSetRecord(
                setNumber: set.setNumber,
                reps: set.reps,
                weight: set.weight,
                restSeconds: set.restSeconds,
                createdAt: set.createdAt,
                isWarmup: set.isWarmup,
              );
            }).toList(),
          );
        }).toList(),
      );

      await _workoutRepository.saveSession(session);
      await _workoutDraftService.clearDraft();
      await _endLiveActivity();

      if (!mounted) return;

      if (personalRecords.isNotEmpty) {
        await _showPersonalRecordsDialog(personalRecords);
      }

      if (!mounted) return;

      _showMessage(
        personalRecords.isNotEmpty
            ? '${personalRecords.length} PRs nuevos guardados'
            : finishDecision.notes == null
                ? 'Entrenamiento guardado'
                : 'Entrenamiento y nota guardados',
      );
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildTopSummary() {
    return WorkoutHeaderPanel(
      title: widget.title,
      elapsedLabel: _formatDuration(_elapsedSeconds),
      exerciseCountLabel: '${_selectedExercises.length}',
      totalSetsLabel: '$_totalSets',
      totalWorkingSetsLabel: '$_totalWorkingSets',
      totalWarmupSetsLabel: '$_totalWarmupSets',
      totalVolumeLabel: _formatCompactVolume(_totalVolume),
      restLabel: _hasStartedRestTracking
          ? _formatRestLabel(_currentRestSeconds)
          : 'Sin iniciar',
    );
  }

  Widget _buildActionBar() {
    return WorkoutActionBar(
      isSaving: _isSaving,
      onAddExercise: _showExercisePicker,
      onFinish: _finishWorkout,
    );
  }

  List<WorkoutTagChipData> _buildExerciseReferenceTags(Exercise exercise) {
    final snapshot = _statsForExercise(exercise);

    if (snapshot == null) {
      return const [
        WorkoutTagChipData(
          icon: Icons.info_outline_rounded,
          label: 'Sin historial todavía',
        ),
      ];
    }

    return [
      WorkoutTagChipData(
        icon: Icons.history_rounded,
        label:
            'Última vez ${_formatWeight(snapshot.lastWeight)} × ${snapshot.lastReps}',
      ),
      WorkoutTagChipData(
        icon: Icons.emoji_events_outlined,
        label: 'PR ${_formatWeight(snapshot.prWeight)} × ${snapshot.prReps}',
      ),
    ];
  }

  WorkoutSetCardData _buildSetCardData(_WorkoutSetEntry set) {
    return WorkoutSetCardData(
      setNumber: set.setNumber,
      isWarmup: set.isWarmup,
      performanceLabel: '${_formatWeight(set.weight)} kg × ${set.reps} reps',
      restLabel: 'Descanso ${_formatRestLabel(set.restSeconds)}',
      volumeLabel: 'Volumen ${_formatCompactVolume(set.weight * set.reps)}',
    );
  }

  // Tarjeta principal de cada ejercicio dentro del entrenamiento.
  // Ahora incluye handle de arrastre para reordenar.
  Widget _buildExerciseCard(_WorkoutExerciseEntry entry, int index) {
    final exerciseVolume = _exerciseVolume(entry);
    final isCustom = entry.exercise.isCustom;
    final warmupCount = _exerciseWarmupCount(entry);

    final summaryTags = <WorkoutTagChipData>[
      WorkoutTagChipData(
        icon: Icons.category_outlined,
        label: entry.exercise.muscleGroup,
      ),
      WorkoutTagChipData(
        icon: isCustom ? Icons.auto_fix_high_rounded : Icons.layers_outlined,
        label: isCustom ? 'Personalizado' : 'Base',
      ),
      WorkoutTagChipData(
        icon: Icons.layers_rounded,
        label: '${entry.sets.length} series',
      ),
      WorkoutTagChipData(
        icon: Icons.local_fire_department_outlined,
        label: '${_exerciseWorkingCount(entry)} efectivas',
      ),
      if (warmupCount > 0)
        WorkoutTagChipData(
          icon: Icons.wb_sunny_outlined,
          label: '$warmupCount calent.',
        ),
      WorkoutTagChipData(
        icon: Icons.monitor_weight_outlined,
        label: _formatCompactVolume(exerciseVolume),
      ),
    ];

    return WorkoutExerciseCard(
      key: ValueKey('exercise_${entry.exercise.id}'),
      title: entry.exercise.name,
      summaryTags: summaryTags,
      referenceTags: _buildExerciseReferenceTags(entry.exercise),
      setCards: [
        for (final set in entry.sets) _buildSetCardData(set),
      ],
      onAddSet: () => _showSetEditorSheet(entry),
      onDuplicateLastSet:
          entry.sets.isEmpty ? null : () => _duplicateLastSet(entry),
      onRemoveExercise: () => _removeExercise(entry),
      onEditSet: (setIndex) => _showSetEditorSheet(entry, setIndex: setIndex),
      onDeleteSet: (setIndex) => _deleteSet(entry, setIndex),
      dragHandle: ReorderableDragStartListener(
        index: index,
        child: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Icon(
            Icons.drag_handle_rounded,
            color: Colors.white.withValues(alpha: 0.70),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return WorkoutEmptyStateCard(onAddExercise: _showExercisePicker);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final navigator = Navigator.of(context);
        final shouldLeave = await _confirmDiscardWorkout();

        if (!mounted || !shouldLeave) return;

        navigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldLeave = await _confirmDiscardWorkout();
              if (!context.mounted || !shouldLeave) return;
              Navigator.of(context).pop();
            },
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            children: [
              _buildTopSummary(),
              const SizedBox(height: 16),
              _buildActionBar(),
              const SizedBox(height: 16),
              if (_selectedExercises.isEmpty)
                _buildEmptyState()
              else ...[
                if (_selectedExercises.length > 1)
                  const WorkoutReorderHintCard(),
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: _selectedExercises.length,
                  onReorder: _reorderExercises,
                  proxyDecorator: (child, index, animation) {
                    return Material(color: Colors.transparent, child: child);
                  },
                  itemBuilder: (context, index) {
                    return _buildExerciseCard(_selectedExercises[index], index);
                  },
                ),
              ],
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showExercisePicker,
          icon: const Icon(Icons.add),
          label: const Text('Ejercicio'),
        ),
      ),
    );
  }
}
