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
  static const Color _panelColor = Color(0xFF171C25);
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
    final customExercises = await _customExerciseRepository
        .getAllCustomExercises();

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

    final shouldRestore =
        await showDialog<bool>(
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

    final shouldLeave =
        await showDialog<bool>(
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
        alreadySelectedIds: _selectedExercises
            .map((e) => e.exercise.id)
            .toSet(),
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
    final previousSet = !isEditing && entry.sets.isNotEmpty
        ? entry.sets.last
        : null;
    final snapshot = _statsForExercise(entry.exercise);

    final result = await showModalBottomSheet<_SetEditorResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151922),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return _SetEditorSheet(
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

      _showMessage('Entrenamiento guardado');
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF172235), Color(0xFF1D3A45)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Entrenamiento libre',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tiempo',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDuration(_elapsedSeconds),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SummaryChip(
                icon: Icons.fitness_center_rounded,
                label: 'Ejercicios',
                value: '${_selectedExercises.length}',
              ),
              _SummaryChip(
                icon: Icons.layers_outlined,
                label: 'Series',
                value: '$_totalSets',
              ),
              _SummaryChip(
                icon: Icons.local_fire_department_outlined,
                label: 'Efectivas',
                value: '$_totalWorkingSets',
              ),
              _SummaryChip(
                icon: Icons.wb_sunny_outlined,
                label: 'Calent.',
                value: '$_totalWarmupSets',
              ),
              _SummaryChip(
                icon: Icons.monitor_weight_outlined,
                label: 'Volumen',
                value: _formatCompactVolume(_totalVolume),
              ),
              _SummaryChip(
                icon: Icons.timer_outlined,
                label: 'Descanso',
                value: _hasStartedRestTracking
                    ? _formatRestLabel(_currentRestSeconds)
                    : 'Sin iniciar',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: _showExercisePicker,
            icon: const Icon(Icons.add),
            label: const Text('Añadir ejercicio'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isSaving ? null : _finishWorkout,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline_rounded),
            label: Text(_isSaving ? 'Guardando...' : 'Finalizar'),
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseReference(Exercise exercise) {
    final snapshot = _statsForExercise(exercise);

    if (snapshot == null) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: const [
          _MiniTagChip(
            icon: Icons.info_outline_rounded,
            label: 'Sin historial todavía',
          ),
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MiniTagChip(
          icon: Icons.history_rounded,
          label:
              'Última vez ${_formatWeight(snapshot.lastWeight)} × ${snapshot.lastReps}',
        ),
        _MiniTagChip(
          icon: Icons.emoji_events_outlined,
          label: 'PR ${_formatWeight(snapshot.prWeight)} × ${snapshot.prReps}',
        ),
      ],
    );
  }

  Widget _buildSetCard(
    _WorkoutExerciseEntry entry,
    _WorkoutSetEntry set,
    int index,
  ) {
    final isWarmup = set.isWarmup;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isWarmup
            ? const Color(0xFFFFB74D).withValues(alpha: 0.08)
            : _panelSoftColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isWarmup
              ? const Color(0xFFFFB74D).withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isWarmup
                  ? const Color(0xFFFFB74D).withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${set.setNumber}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_formatWeight(set.weight)} kg × ${set.reps} reps',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _MiniTagChip(
                      icon: isWarmup
                          ? Icons.wb_sunny_outlined
                          : Icons.local_fire_department_outlined,
                      label: isWarmup ? 'Calentamiento' : 'Serie efectiva',
                    ),
                    _MiniTagChip(
                      icon: Icons.timelapse_rounded,
                      label: 'Descanso ${_formatRestLabel(set.restSeconds)}',
                    ),
                    _MiniTagChip(
                      icon: Icons.fitness_center_rounded,
                      label:
                          'Volumen ${_formatCompactVolume(set.weight * set.reps)}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'edit') {
                _showSetEditorSheet(entry, setIndex: index);
              } else if (value == 'delete') {
                _deleteSet(entry, index);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Editar serie')),
              PopupMenuItem(value: 'delete', child: Text('Eliminar serie')),
            ],
          ),
        ],
      ),
    );
  }

  // Tarjeta principal de cada ejercicio dentro del entrenamiento.
  // Ahora incluye handle de arrastre para reordenar.
  Widget _buildExerciseCard(_WorkoutExerciseEntry entry, int index) {
    final exerciseVolume = _exerciseVolume(entry);
    final isCustom = entry.exercise.isCustom;

    return Card(
      key: ValueKey('exercise_${entry.exercise.id}'),
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.sports_gymnastics_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.exercise.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _MiniTagChip(
                            icon: Icons.category_outlined,
                            label: entry.exercise.muscleGroup,
                          ),
                          _MiniTagChip(
                            icon: isCustom
                                ? Icons.auto_fix_high_rounded
                                : Icons.layers_outlined,
                            label: isCustom ? 'Personalizado' : 'Base',
                          ),
                          _MiniTagChip(
                            icon: Icons.layers_rounded,
                            label: '${entry.sets.length} series',
                          ),
                          _MiniTagChip(
                            icon: Icons.local_fire_department_outlined,
                            label: '${_exerciseWorkingCount(entry)} efectivas',
                          ),
                          if (_exerciseWarmupCount(entry) > 0)
                            _MiniTagChip(
                              icon: Icons.wb_sunny_outlined,
                              label: '${_exerciseWarmupCount(entry)} calent.',
                            ),
                          _MiniTagChip(
                            icon: Icons.monitor_weight_outlined,
                            label: _formatCompactVolume(exerciseVolume),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'addSet') {
                      _showSetEditorSheet(entry);
                    } else if (value == 'duplicate') {
                      _duplicateLastSet(entry);
                    } else if (value == 'removeExercise') {
                      _removeExercise(entry);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'addSet', child: Text('Añadir serie')),
                    PopupMenuItem(
                      value: 'duplicate',
                      child: Text('Duplicar última serie'),
                    ),
                    PopupMenuItem(
                      value: 'removeExercise',
                      child: Text('Quitar ejercicio'),
                    ),
                  ],
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.drag_handle_rounded,
                      color: Colors.white.withValues(alpha: 0.70),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildExerciseReference(entry.exercise),
            const SizedBox(height: 14),
            if (entry.sets.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Todavía no hay series',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Añade la primera serie para empezar a registrar este ejercicio.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () => _showSetEditorSheet(entry),
                      icon: const Icon(Icons.add),
                      label: const Text('Añadir primera serie'),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  for (int i = 0; i < entry.sets.length; i++)
                    _buildSetCard(entry, entry.sets[i], i),
                ],
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showSetEditorSheet(entry),
                    icon: const Icon(Icons.add),
                    label: const Text('Nueva serie'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: entry.sets.isEmpty
                        ? null
                        : () => _duplicateLastSet(entry),
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Duplicar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _panelColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.fitness_center_rounded, size: 34),
          ),
          const SizedBox(height: 16),
          const Text(
            'Empieza tu entrenamiento',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Añade ejercicios y registra series con peso, repeticiones y descanso automático.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.74),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _showExercisePicker,
            icon: const Icon(Icons.add),
            label: const Text('Añadir primer ejercicio'),
          ),
        ],
      ),
    );
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
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _panelSoftColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Mantén el icono de arrastre para reordenar ejercicios.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniTagChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniTagChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _QuickFillChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickFillChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.white.withValues(alpha: 0.08),
      side: BorderSide.none,
      labelStyle: const TextStyle(fontSize: 12),
    );
  }
}

class _QuickAdjustChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickAdjustChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.white.withValues(alpha: 0.06),
      side: BorderSide.none,
      labelStyle: const TextStyle(fontSize: 12),
    );
  }
}

class _ExercisePickerSheet extends StatefulWidget {
  final List<Exercise> exercises;
  final Set<String> alreadySelectedIds;

  const _ExercisePickerSheet({
    required this.exercises,
    required this.alreadySelectedIds,
  });

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FavoriteExercisesService _favoriteExercisesService =
      const FavoriteExercisesService();

  String _query = '';
  String? _selectedMuscleGroup;
  bool _showFavoritesOnly = false;
  bool _isLoadingFavorites = true;
  Set<String> _favoriteIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  List<Exercise> get _availableExercisesExcludingSelected {
    return widget.exercises.where((exercise) {
      return !widget.alreadySelectedIds.contains(exercise.id);
    }).toList();
  }

  List<String> get _muscleGroups {
    final groups =
        _availableExercisesExcludingSelected
            .map((e) => e.muscleGroup)
            .toSet()
            .toList()
          ..sort();
    return groups;
  }

  int get _favoriteCountInScope {
    return _availableExercisesExcludingSelected
        .where((exercise) => _favoriteIds.contains(exercise.id))
        .length;
  }

  Future<void> _loadFavorites() async {
    final favoriteIds = await _favoriteExercisesService.getFavoriteIds();

    if (!mounted) return;

    setState(() {
      _favoriteIds = favoriteIds;
      _isLoadingFavorites = false;
    });
  }

  Future<void> _toggleFavorite(Exercise exercise) async {
    final isNowFavorite = await _favoriteExercisesService.toggleFavorite(
      exercise.id,
    );

    if (!mounted) return;

    setState(() {
      if (isNowFavorite) {
        _favoriteIds.add(exercise.id);
      } else {
        _favoriteIds.remove(exercise.id);
      }
    });
  }

  int _compareExercises(Exercise a, Exercise b) {
    final aIsFavorite = _favoriteIds.contains(a.id);
    final bIsFavorite = _favoriteIds.contains(b.id);

    if (aIsFavorite != bIsFavorite) {
      return aIsFavorite ? -1 : 1;
    }

    if (a.isCustom != b.isCustom) {
      return a.isCustom ? -1 : 1;
    }

    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  List<Exercise> get _filteredExercises {
    final query = _query.trim().toLowerCase();

    final filtered = _availableExercisesExcludingSelected.where((exercise) {
      final matchesQuery =
          query.isEmpty ||
          exercise.name.toLowerCase().contains(query) ||
          exercise.muscleGroup.toLowerCase().contains(query) ||
          exercise.tags.any((tag) => tag.toLowerCase().contains(query));

      final matchesGroup =
          _selectedMuscleGroup == null ||
          exercise.muscleGroup == _selectedMuscleGroup;

      final matchesFavorites =
          !_showFavoritesOnly || _favoriteIds.contains(exercise.id);

      return matchesQuery && matchesGroup && matchesFavorites;
    }).toList();

    filtered.sort(_compareExercises);
    return filtered;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercises = _filteredExercises;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Añadir ejercicio',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Favoritos primero para encontrarlos más rápido al entrenar',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _query = value;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Ejemplo: press, espalda, unilateral...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected:
                          !_showFavoritesOnly && _selectedMuscleGroup == null,
                      label: const Text('Todos'),
                      onSelected: (_) {
                        setState(() {
                          _showFavoritesOnly = false;
                          _selectedMuscleGroup = null;
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: _showFavoritesOnly,
                      label: Text('Favoritos ($_favoriteCountInScope)'),
                      onSelected: (_) {
                        setState(() {
                          _showFavoritesOnly = true;
                        });
                      },
                    ),
                  ),
                  ..._muscleGroups.map((group) {
                    final selected = _selectedMuscleGroup == group;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: selected,
                        label: Text(group),
                        onSelected: (_) {
                          setState(() {
                            _selectedMuscleGroup = selected ? null : group;
                            _showFavoritesOnly = false;
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (_isLoadingFavorites)
              const LinearProgressIndicator()
            else
              Text(
                '${exercises.length} ejercicios disponibles',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
              ),
            const SizedBox(height: 10),
            Flexible(
              child: _isLoadingFavorites
                  ? const Center(child: CircularProgressIndicator())
                  : exercises.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _showFavoritesOnly
                              ? 'No tienes favoritos disponibles con ese filtro'
                              : 'No hay ejercicios que coincidan con tu búsqueda',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: exercises.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final exercise = exercises[index];
                        final isFavorite = _favoriteIds.contains(exercise.id);

                        return Material(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => Navigator.of(context).pop(exercise),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.sports_gymnastics_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                exercise.name,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              tooltip: isFavorite
                                                  ? 'Quitar de favoritos'
                                                  : 'Añadir a favoritos',
                                              onPressed: () =>
                                                  _toggleFavorite(exercise),
                                              icon: Icon(
                                                isFavorite
                                                    ? Icons.star_rounded
                                                    : Icons.star_border_rounded,
                                                color: isFavorite
                                                    ? Colors.amber
                                                    : Colors.white70,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          exercise.muscleGroup,
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.72,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            if (isFavorite)
                                              const _MiniTagChip(
                                                icon: Icons.star_rounded,
                                                label: 'Favorito',
                                              ),
                                            ...exercise.tags
                                                .take(3)
                                                .map(
                                                  (tag) => _MiniTagChip(
                                                    icon: Icons.sell_outlined,
                                                    label: tag,
                                                  ),
                                                ),
                                            _MiniTagChip(
                                              icon: exercise.isCustom
                                                  ? Icons.auto_fix_high_rounded
                                                  : Icons.layers_outlined,
                                              label: exercise.isCustom
                                                  ? 'Custom'
                                                  : 'Base',
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right_rounded),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetEditorResult {
  final double weight;
  final int reps;
  final bool isWarmup;

  const _SetEditorResult({
    required this.weight,
    required this.reps,
    required this.isWarmup,
  });
}

class _SetEditorSheet extends StatefulWidget {
  final bool isEditing;
  final String exerciseName;
  final Color panelColor;
  final String initialWeightText;
  final String initialRepsText;
  final double? previousSetWeight;
  final int? previousSetReps;
  final bool previousSetIsWarmup;
  final bool initialIsWarmup;
  final double? lastWeight;
  final int? lastReps;
  final double? prWeight;
  final int? prReps;
  final String restLabel;
  final String Function(double value) formatWeight;

  const _SetEditorSheet({
    required this.isEditing,
    required this.exerciseName,
    required this.panelColor,
    required this.initialWeightText,
    required this.initialRepsText,
    required this.previousSetWeight,
    required this.previousSetReps,
    required this.previousSetIsWarmup,
    required this.initialIsWarmup,
    required this.lastWeight,
    required this.lastReps,
    required this.prWeight,
    required this.prReps,
    required this.restLabel,
    required this.formatWeight,
  });

  @override
  State<_SetEditorSheet> createState() => _SetEditorSheetState();
}

class _SetEditorSheetState extends State<_SetEditorSheet> {
  late final TextEditingController _weightController;
  late final TextEditingController _repsController;
  late bool _isWarmup;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(text: widget.initialWeightText);
    _repsController = TextEditingController(text: widget.initialRepsText);
    _isWarmup = widget.initialIsWarmup;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  double _parseWeight() {
    return double.tryParse(
          _weightController.text.trim().replaceAll(',', '.'),
        ) ??
        0;
  }

  int _parseReps() {
    return int.tryParse(_repsController.text.trim()) ?? 0;
  }

  void _setWeight(double value) {
    final safeValue = value < 0 ? 0.0 : value;

    setState(() {
      _weightController.text = widget.formatWeight(safeValue);
      _weightController.selection = TextSelection.fromPosition(
        TextPosition(offset: _weightController.text.length),
      );
    });
  }

  void _setReps(int value) {
    final safeValue = value < 1 ? 1 : value;

    setState(() {
      _repsController.text = '$safeValue';
      _repsController.selection = TextSelection.fromPosition(
        TextPosition(offset: _repsController.text.length),
      );
    });
  }

  void _save() {
    FocusScope.of(context).unfocus();

    final weight = double.tryParse(
      _weightController.text.trim().replaceAll(',', '.'),
    );
    final reps = int.tryParse(_repsController.text.trim());

    if (weight == null || reps == null || weight < 0 || reps <= 0) {
      setState(() {
        _errorText = 'Introduce un peso y reps válidos';
      });
      return;
    }

    Navigator.of(context).pop(
      _SetEditorResult(weight: weight, reps: reps, isWarmup: _isWarmup),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              widget.isEditing ? 'Editar serie' : 'Añadir serie',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              widget.exerciseName,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.panelColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Referencia rápida',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (widget.previousSetWeight != null &&
                          widget.previousSetReps != null)
                        _QuickFillChip(
                          label:
                              '${widget.previousSetIsWarmup ? 'Últ. calent.' : 'Última serie'} ${widget.formatWeight(widget.previousSetWeight!)} × ${widget.previousSetReps}',
                          onTap: () {
                            _setWeight(widget.previousSetWeight!);
                            _setReps(widget.previousSetReps!);
                          },
                        ),
                      if (widget.lastWeight != null && widget.lastReps != null)
                        _QuickFillChip(
                          label:
                              'Última vez ${widget.formatWeight(widget.lastWeight!)} × ${widget.lastReps}',
                          onTap: () {
                            _setWeight(widget.lastWeight!);
                            _setReps(widget.lastReps!);
                          },
                        ),
                      if (widget.prWeight != null && widget.prReps != null)
                        _QuickFillChip(
                          label:
                              'PR ${widget.formatWeight(widget.prWeight!)} × ${widget.prReps}',
                          onTap: () {
                            _setWeight(widget.prWeight!);
                            _setReps(widget.prReps!);
                          },
                        ),
                      if (widget.previousSetWeight == null &&
                          widget.lastWeight == null &&
                          widget.prWeight == null)
                        const _MiniTagChip(
                          icon: Icons.info_outline_rounded,
                          label: 'Sin referencias todavía',
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Peso (kg)',
                      errorText: _errorText,
                    ),
                    onChanged: (_) {
                      if (_errorText != null) {
                        setState(() {
                          _errorText = null;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _repsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Repeticiones',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Tipo de serie',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Serie efectiva'),
                  selected: !_isWarmup,
                  onSelected: (_) {
                    setState(() {
                      _isWarmup = false;
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('Calentamiento'),
                  selected: _isWarmup,
                  onSelected: (_) {
                    setState(() {
                      _isWarmup = true;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Ajustes rápidos',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickAdjustChip(
                  label: '+2.5 kg',
                  onTap: () => _setWeight(_parseWeight() + 2.5),
                ),
                _QuickAdjustChip(
                  label: '+5 kg',
                  onTap: () => _setWeight(_parseWeight() + 5),
                ),
                _QuickAdjustChip(
                  label: '-2.5 kg',
                  onTap: () => _setWeight(_parseWeight() - 2.5),
                ),
                _QuickAdjustChip(
                  label: '+1 rep',
                  onTap: () => _setReps(_parseReps() + 1),
                ),
                _QuickAdjustChip(
                  label: '+2 reps',
                  onTap: () => _setReps(_parseReps() + 2),
                ),
                _QuickAdjustChip(
                  label: '-1 rep',
                  onTap: () => _setReps(_parseReps() - 1),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Descanso que se guardará',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.restLabel,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isWarmup
                        ? 'Se guardará como serie de calentamiento'
                        : 'Se guardará como serie efectiva',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.68),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: Text(
                      widget.isEditing ? 'Guardar cambios' : 'Guardar serie',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
