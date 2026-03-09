import 'dart:async';

import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../models/workout_session.dart';
import '../repositories/custom_exercise_repository.dart';
import '../repositories/workout_repository.dart';
import '../services/app_repositories.dart';

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
  static const Color _panelColor = Color(0xFF171C25);
  static const Color _panelSoftColor = Color(0xFF1C2330);
  static const Color _accentColor = Color(0xFF4FC3F7);
  static const Color _successColor = Color(0xFF4ADE80);
  static const Color _warningColor = Color(0xFFFBBF24);

  final WorkoutRepository _workoutRepository = AppRepositories.workouts;
  final CustomExerciseRepository _customExerciseRepository =
      AppRepositories.customExercises;

  final List<_WorkoutExerciseEntry> _selectedExercises = [];
  final List<Exercise> _customExercises = [];

  Map<String, ExercisePerformanceSnapshot> _exerciseSnapshots = {};

  late final DateTime _startedAt;
  Timer? _workoutTimer;
  Timer? _restTimer;

  int _elapsedSeconds = 0;
  int _currentRestSeconds = 0;
  bool _isSaving = false;
  bool _hasStartedRestTracking = false;

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

  @override
  void dispose() {
    _workoutTimer?.cancel();
    _restTimer?.cancel();
    super.dispose();
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _restartRestStopwatch() {
    _restTimer?.cancel();

    setState(() {
      _currentRestSeconds = 0;
      _hasStartedRestTracking = true;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _currentRestSeconds++;
      });
    });
  }

  Future<void> _openExercisePicker() async {
    final selectedIds = _selectedExercises
        .map((entry) => entry.exercise.id)
        .toSet();
    final searchController = TextEditingController();
    String search = '';

    final pickedExercise = await showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151922),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query = search.trim().toLowerCase();

            final available = _allAvailableExercises.where((exercise) {
              final notSelected = !selectedIds.contains(exercise.id);
              final matchesSearch =
                  query.isEmpty ||
                  exercise.name.toLowerCase().contains(query) ||
                  exercise.muscleGroup.toLowerCase().contains(query) ||
                  exercise.tags.any((tag) => tag.toLowerCase().contains(query));
              return notSelected && matchesSearch;
            }).toList();

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: SizedBox(
                  height: 620,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Añadir ejercicio',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Busca por nombre, grupo muscular o tag.',
                        style: TextStyle(color: Colors.white.withOpacity(0.72)),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: searchController,
                        onChanged: (value) {
                          setModalState(() {
                            search = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre o tag',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: search.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    searchController.clear();
                                    setModalState(() {
                                      search = '';
                                    });
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '${available.length} disponibles',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.72),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: available.isEmpty
                            ? _buildPickerEmptyState()
                            : ListView.separated(
                                itemCount: available.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final exercise = available[index];
                                  final stats = _statsForExercise(exercise);

                                  return Container(
                                    decoration: BoxDecoration(
                                      color: _panelSoftColor,
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.05),
                                      ),
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(22),
                                      onTap: () =>
                                          Navigator.pop(context, exercise),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
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
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: _accentColor
                                                        .withOpacity(0.12),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          999,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    exercise.isCustom
                                                        ? 'Custom'
                                                        : 'Añadir',
                                                    style: const TextStyle(
                                                      color: _accentColor,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              exercise.muscleGroup,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.white.withOpacity(
                                                  0.7,
                                                ),
                                              ),
                                            ),
                                            if (exercise.tags.isNotEmpty) ...[
                                              const SizedBox(height: 12),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: exercise.tags
                                                    .take(4)
                                                    .map(
                                                      (tag) => _MiniTagChip(
                                                        label: tag,
                                                      ),
                                                    )
                                                    .toList(),
                                              ),
                                            ],
                                            const SizedBox(height: 12),
                                            if (stats != null)
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: [
                                                  _MiniTagChip(
                                                    icon: Icons.history_rounded,
                                                    label:
                                                        'Última ${_formatWeight(stats.lastWeight)}×${stats.lastReps}',
                                                  ),
                                                  _MiniTagChip(
                                                    icon: Icons
                                                        .emoji_events_outlined,
                                                    label:
                                                        'PR ${_formatWeight(stats.prWeight)}×${stats.prReps}',
                                                  ),
                                                ],
                                              )
                                            else
                                              const _MiniTagChip(
                                                icon: Icons.history_toggle_off,
                                                label: 'Sin historial',
                                              ),
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
              ),
            );
          },
        );
      },
    );

    searchController.dispose();

    if (pickedExercise == null) return;

    setState(() {
      _selectedExercises.add(_WorkoutExerciseEntry(exercise: pickedExercise));
    });
  }

  Widget _buildPickerEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _panelSoftColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 42,
            color: Colors.white.withOpacity(0.55),
          ),
          const SizedBox(height: 14),
          const Text(
            'No hay ejercicios para esa búsqueda',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Prueba otro nombre, otro tag o revisa si ya lo añadiste a la sesión.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.7), height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceChips(Exercise exercise) {
    final stats = _statsForExercise(exercise);

    if (stats == null) {
      return const _InfoChip(
        icon: Icons.history_toggle_off_rounded,
        label: 'Sin historial',
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _InfoChip(
          icon: Icons.history_rounded,
          label:
              'Última ${_formatWeight(stats.lastWeight)} kg × ${stats.lastReps}',
        ),
        _InfoChip(
          icon: Icons.emoji_events_outlined,
          label: 'PR ${_formatWeight(stats.prWeight)} kg × ${stats.prReps}',
        ),
      ],
    );
  }

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

    final weightController = TextEditingController(
      text: existingSet != null
          ? _formatWeight(existingSet.weight)
          : previousSet != null
          ? _formatWeight(previousSet.weight)
          : snapshot != null
          ? _formatWeight(snapshot.lastWeight)
          : '',
    );

    final repsController = TextEditingController(
      text: existingSet != null
          ? existingSet.reps.toString()
          : previousSet != null
          ? previousSet.reps.toString()
          : snapshot != null
          ? snapshot.lastReps.toString()
          : '',
    );

    double parseWeight() {
      return double.tryParse(
            weightController.text.trim().replaceAll(',', '.'),
          ) ??
          0;
    }

    int parseReps() {
      return int.tryParse(repsController.text.trim()) ?? 0;
    }

    void setWeight(StateSetter setModalState, double value) {
      final double safeValue = value < 0 ? 0.0 : value;

      setModalState(() {
        weightController.text = _formatWeight(safeValue);
        weightController.selection = TextSelection.fromPosition(
          TextPosition(offset: weightController.text.length),
        );
      });
    }

    void setReps(StateSetter setModalState, int value) {
      final int safeValue = value < 1 ? 1 : value;

      setModalState(() {
        repsController.text = '$safeValue';
        repsController.selection = TextSelection.fromPosition(
          TextPosition(offset: repsController.text.length),
        );
      });
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151922),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      isEditing ? 'Editar serie' : 'Añadir serie',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      entry.exercise.name,
                      style: TextStyle(color: Colors.white.withOpacity(0.72)),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _panelSoftColor,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Referencia rápida',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (previousSet != null)
                                _QuickFillChip(
                                  label:
                                      'Última serie ${_formatWeight(previousSet.weight)}×${previousSet.reps}',
                                  onTap: () {
                                    setWeight(
                                      setModalState,
                                      previousSet.weight,
                                    );
                                    setReps(setModalState, previousSet.reps);
                                  },
                                ),
                              if (snapshot != null)
                                _QuickFillChip(
                                  label:
                                      'Última vez ${_formatWeight(snapshot.lastWeight)}×${snapshot.lastReps}',
                                  onTap: () {
                                    setWeight(
                                      setModalState,
                                      snapshot.lastWeight,
                                    );
                                    setReps(setModalState, snapshot.lastReps);
                                  },
                                ),
                              if (snapshot != null)
                                _QuickFillChip(
                                  label:
                                      'PR ${_formatWeight(snapshot.prWeight)}×${snapshot.prReps}',
                                  onTap: () {
                                    setWeight(setModalState, snapshot.prWeight);
                                    setReps(setModalState, snapshot.prReps);
                                  },
                                ),
                              if (previousSet == null && snapshot == null)
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
                            controller: weightController,
                            autofocus: true,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Peso (kg)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: repsController,
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
                      'Ajustes rápidos',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _QuickAdjustChip(
                          label: '+2.5 kg',
                          onTap: () =>
                              setWeight(setModalState, parseWeight() + 2.5),
                        ),
                        _QuickAdjustChip(
                          label: '+5 kg',
                          onTap: () =>
                              setWeight(setModalState, parseWeight() + 5),
                        ),
                        _QuickAdjustChip(
                          label: '-2.5 kg',
                          onTap: () =>
                              setWeight(setModalState, parseWeight() - 2.5),
                        ),
                        _QuickAdjustChip(
                          label: '+1 rep',
                          onTap: () => setReps(setModalState, parseReps() + 1),
                        ),
                        _QuickAdjustChip(
                          label: '+2 reps',
                          onTap: () => setReps(setModalState, parseReps() + 2),
                        ),
                        _QuickAdjustChip(
                          label: '-1 rep',
                          onTap: () => setReps(setModalState, parseReps() - 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Descanso que se guardará',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isEditing
                                ? _formatRestLabel(existingSet!.restSeconds)
                                : _hasStartedRestTracking
                                ? _formatRestLabel(_currentRestSeconds)
                                : '0s',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
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
                            onPressed: () => Navigator.pop(sheetContext),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              final weight = double.tryParse(
                                weightController.text.trim().replaceAll(
                                  ',',
                                  '.',
                                ),
                              );
                              final reps = int.tryParse(
                                repsController.text.trim(),
                              );

                              if (weight == null ||
                                  reps == null ||
                                  weight < 0 ||
                                  reps <= 0) {
                                _showMessage(
                                  'Introduce un peso y reps válidos',
                                );
                                return;
                              }

                              setState(() {
                                if (isEditing) {
                                  entry.sets[setIndex] = _WorkoutSetEntry(
                                    setNumber: existingSet!.setNumber,
                                    reps: reps,
                                    weight: weight,
                                    restSeconds: existingSet.restSeconds,
                                    createdAt: existingSet.createdAt,
                                  );
                                } else {
                                  entry.sets.add(
                                    _WorkoutSetEntry(
                                      setNumber: entry.sets.length + 1,
                                      reps: reps,
                                      weight: weight,
                                      restSeconds: _hasStartedRestTracking
                                          ? _currentRestSeconds
                                          : 0,
                                      createdAt: DateTime.now(),
                                    ),
                                  );
                                }
                              });

                              if (!isEditing) {
                                _restartRestStopwatch();
                              }

                              Navigator.pop(sheetContext);
                              _showMessage(
                                isEditing
                                    ? 'Serie actualizada'
                                    : 'Serie guardada',
                              );
                            },
                            child: Text(
                              isEditing ? 'Guardar cambios' : 'Guardar serie',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    weightController.dispose();
    repsController.dispose();
  }

  Future<void> _deleteSet(_WorkoutExerciseEntry entry, int setIndex) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Eliminar serie'),
              content: const Text(
                'Esta acción quitará la serie del ejercicio.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Eliminar'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) return;

    setState(() {
      entry.sets.removeAt(setIndex);

      for (int index = 0; index < entry.sets.length; index++) {
        final current = entry.sets[index];
        entry.sets[index] = _WorkoutSetEntry(
          setNumber: index + 1,
          reps: current.reps,
          weight: current.weight,
          restSeconds: current.restSeconds,
          createdAt: current.createdAt,
        );
      }
    });

    _showMessage('Serie eliminada');
  }

  Future<void> _removeExercise(_WorkoutExerciseEntry entry) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Quitar ejercicio'),
              content: Text(
                'Se eliminará ${entry.exercise.name} del entrenamiento actual.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Quitar'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) return;

    setState(() {
      _selectedExercises.remove(entry);
    });

    _showMessage('Ejercicio quitado');
  }

  void _duplicateLastSet(_WorkoutExerciseEntry entry) {
    if (entry.sets.isEmpty) {
      _showMessage('Primero añade una serie manualmente');
      return;
    }

    final lastSet = entry.sets.last;

    setState(() {
      entry.sets.add(
        _WorkoutSetEntry(
          setNumber: entry.sets.length + 1,
          reps: lastSet.reps,
          weight: lastSet.weight,
          restSeconds: _hasStartedRestTracking ? _currentRestSeconds : 0,
          createdAt: DateTime.now(),
        ),
      );
    });

    _restartRestStopwatch();
    _showMessage('Última serie duplicada');
  }

  Future<void> _finishWorkout() async {
    if (_selectedExercises.isEmpty) {
      _showMessage('Añade al menos un ejercicio antes de guardar');
      return;
    }

    final exercisesWithSets = _selectedExercises
        .where((entry) => entry.sets.isNotEmpty)
        .toList();

    if (exercisesWithSets.isEmpty) {
      _showMessage('Añade al menos una serie antes de guardar');
      return;
    }

    final finishedAt = DateTime.now();
    final sessionTags = _buildSessionTags(exercisesWithSets);

    final session = WorkoutSession(
      id: finishedAt.microsecondsSinceEpoch.toString(),
      routineId: 'free_workout',
      routineName: widget.title,
      startedAt: _startedAt,
      finishedAt: finishedAt,
      durationSeconds: _elapsedSeconds,
      sessionTags: sessionTags,
      exercises: exercisesWithSets.map((entry) {
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
            );
          }).toList(),
        );
      }).toList(),
      totalVolume: _totalVolume,
    );

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Entrenamiento finalizado'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SummaryRow(label: 'Sesión', value: session.routineName),
                  _SummaryRow(
                    label: 'Ejercicios',
                    value: '${session.totalExercises}',
                  ),
                  _SummaryRow(label: 'Series', value: '${session.totalSets}'),
                  _SummaryRow(
                    label: 'Duración',
                    value: _formatDuration(session.durationSeconds),
                  ),
                  _SummaryRow(
                    label: 'Volumen total',
                    value: '${_formatWeight(session.totalVolume)} kg',
                  ),
                  _SummaryRow(
                    label: 'Etiquetas',
                    value: session.sessionTags.isEmpty
                        ? '--'
                        : session.sessionTags.join(', '),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Seguir entrenando'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _workoutRepository.saveSession(session);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      _showMessage('No se pudo guardar el entrenamiento');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildTopStatsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _panelColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _TopInfoBox(
                  label: 'Duración',
                  value: _formatDuration(_elapsedSeconds),
                  icon: Icons.timer_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TopInfoBox(
                  label: 'Ejercicios',
                  value: '${_selectedExercises.length}',
                  icon: Icons.fitness_center_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TopInfoBox(
                  label: 'Series',
                  value: '$_totalSets',
                  icon: Icons.format_list_numbered_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: _panelSoftColor,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _warningColor.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.timer_rounded, color: _warningColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Descanso actual',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.72),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _hasStartedRestTracking
                            ? _formatDuration(_currentRestSeconds)
                            : '--:--',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _successColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Volumen',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCompactVolume(_totalVolume),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _successColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(_WorkoutExerciseEntry entry) {
    final stats = _statsForExercise(entry.exercise);

    return Container(
      decoration: BoxDecoration(
        color: _panelColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.exercise.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'remove') {
                      _removeExercise(entry);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'remove',
                      child: Text('Quitar ejercicio'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              entry.exercise.muscleGroup,
              style: TextStyle(color: Colors.white.withOpacity(0.68)),
            ),
            if (entry.exercise.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entry.exercise.tags
                    .take(4)
                    .map((tag) => _MiniTagChip(label: tag))
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            _buildReferenceChips(entry.exercise),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MiniTagChip(
                  icon: Icons.layers_outlined,
                  label: '${entry.sets.length} series',
                ),
                _MiniTagChip(
                  icon: Icons.bar_chart_rounded,
                  label: _formatCompactVolume(_exerciseVolume(entry)),
                ),
                if (entry.exercise.isCustom)
                  const _MiniTagChip(
                    icon: Icons.auto_awesome_rounded,
                    label: 'Custom',
                  ),
                if (stats != null)
                  _MiniTagChip(
                    icon: Icons.trending_up_rounded,
                    label:
                        'PR ${_formatWeight(stats.prWeight)} × ${stats.prReps}',
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(child: _SetTableHeader()),
                const SizedBox(width: 8),
                Text(
                  'Acciones',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.58),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (entry.sets.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _panelSoftColor,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  'Todavía no has añadido series a este ejercicio.',
                  style: TextStyle(color: Colors.white.withOpacity(0.72)),
                ),
              )
            else
              Column(
                children: List.generate(entry.sets.length, (index) {
                  final set = entry.sets[index];

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == entry.sets.length - 1 ? 0 : 10,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: _panelSoftColor,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _SetMetricCell(
                                    value: '#${set.setNumber}',
                                    label: 'Serie',
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: _SetMetricCell(
                                    value: '${set.reps}',
                                    label: 'Reps',
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: _SetMetricCell(
                                    value: '${_formatWeight(set.weight)} kg',
                                    label: 'Peso',
                                  ),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: _SetMetricCell(
                                    value: _formatRestLabel(set.restSeconds),
                                    label: 'Descanso',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Editar',
                                onPressed: () {
                                  _showSetEditorSheet(entry, setIndex: index);
                                },
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                tooltip: 'Eliminar',
                                onPressed: () {
                                  _deleteSet(entry, index);
                                },
                                icon: const Icon(Icons.delete_outline_rounded),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _InlineActionButton(
                  icon: Icons.add_rounded,
                  label: 'Añadir serie',
                  onTap: () => _showSetEditorSheet(entry),
                ),
                _InlineActionButton(
                  icon: Icons.copy_rounded,
                  label: 'Duplicar última',
                  onTap: () => _duplicateLastSet(entry),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWorkoutState() {
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _panelColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                size: 34,
                color: _accentColor,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Empieza tu sesión',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Añade ejercicios y registra tus series para guardar el entrenamiento libre.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Colors.white.withOpacity(0.74),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _openExercisePicker,
                style: FilledButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.black87,
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Añadir primer ejercicio'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appBarTitle = widget.title == 'Entrenamiento libre'
        ? 'Entreno libre'
        : widget.title;

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _finishWorkout,
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('Guardar'),
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: _selectedExercises.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _openExercisePicker,
              backgroundColor: _accentColor,
              foregroundColor: Colors.black87,
              icon: const Icon(Icons.add),
              label: const Text('Ejercicio'),
            ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  _buildTopStatsCard(),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Ejercicios del entrenamiento',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${_selectedExercises.length} añadidos',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withOpacity(0.78),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _selectedExercises.isEmpty
                        ? _buildEmptyWorkoutState()
                        : ListView.separated(
                            itemCount: _selectedExercises.length,
                            padding: const EdgeInsets.only(bottom: 90),
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              return _buildExerciseCard(
                                _selectedExercises[index],
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          if (_isSaving)
            Container(
              color: Colors.black.withOpacity(0.35),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class _WorkoutExerciseEntry {
  final Exercise exercise;
  final List<_WorkoutSetEntry> sets;

  _WorkoutExerciseEntry({required this.exercise, List<_WorkoutSetEntry>? sets})
    : sets = sets ?? [];
}

class _WorkoutSetEntry {
  final int setNumber;
  final int reps;
  final double weight;
  final int restSeconds;
  final DateTime createdAt;

  _WorkoutSetEntry({
    required this.setNumber,
    required this.reps,
    required this.weight,
    required this.restSeconds,
    required this.createdAt,
  });
}

class _TopInfoBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _TopInfoBox({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.75),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11.5)),
        ],
      ),
    );
  }
}

class _MiniTagChip extends StatelessWidget {
  final String label;
  final IconData? icon;

  const _MiniTagChip({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: Colors.white70),
            const SizedBox(width: 5),
          ],
          Text(label, style: const TextStyle(fontSize: 11.5)),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
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
      backgroundColor: Colors.white.withOpacity(0.05),
      side: BorderSide(color: Colors.white.withOpacity(0.05)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
    );
  }
}

class _SetTableHeader extends StatelessWidget {
  const _SetTableHeader();

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
      color: Colors.white.withOpacity(0.58),
    );

    return Row(
      children: [
        Expanded(flex: 2, child: Text('SERIE', style: style)),
        Expanded(flex: 3, child: Text('REPS', style: style)),
        Expanded(flex: 3, child: Text('PESO', style: style)),
        Expanded(flex: 4, child: Text('DESCANSO', style: style)),
      ],
    );
  }
}

class _SetMetricCell extends StatelessWidget {
  final String value;
  final String label;

  const _SetMetricCell({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.62)),
        ),
      ],
    );
  }
}

class _InlineActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _InlineActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.white.withOpacity(0.75)),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
