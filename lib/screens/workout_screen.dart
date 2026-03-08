import 'dart:async';

import 'package:flutter/material.dart';

import '../data/workout_storage.dart';
import '../models/exercise.dart';
import '../models/workout_session.dart';

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
  final List<_WorkoutExerciseEntry> _selectedExercises = [];
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
  }

  Future<void> _loadExerciseSnapshots() async {
    final snapshots = await WorkoutStorage.loadExerciseSnapshots();

    if (!mounted) return;

    setState(() {
      _exerciseSnapshots = snapshots;
    });
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

  ExercisePerformanceSnapshot? _statsForExercise(Exercise exercise) {
    return _exerciseSnapshots[exercise.id];
  }

  Widget _buildReferenceChips(Exercise exercise) {
    final stats = _statsForExercise(exercise);

    if (stats == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('Sin historial', style: TextStyle(fontSize: 11)),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Última ${_formatWeight(stats.lastWeight)} kg x ${stats.lastReps}',
            style: const TextStyle(fontSize: 11),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'PR ${_formatWeight(stats.prWeight)} kg x ${stats.prReps}',
            style: const TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
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
    final selectedIds = _selectedExercises.map((e) => e.exercise.id).toSet();
    final searchController = TextEditingController();
    String search = '';

    final Exercise? pickedExercise = await showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151922),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final available = widget.availableExercises.where((exercise) {
              final notSelected = !selectedIds.contains(exercise.id);
              final query = search.trim().toLowerCase();

              final matchesSearch =
                  query.isEmpty ||
                  exercise.name.toLowerCase().contains(query) ||
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
                  height: 560,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: SizedBox(
                          width: 44,
                          child: Divider(thickness: 4),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Añadir ejercicio',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
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
                          filled: true,
                          fillColor: const Color(0xFF1A1F2B),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: available.isEmpty
                            ? Center(
                                child: Text(
                                  'No hay ejercicios disponibles',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.75),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: available.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final exercise = available[index];
                                  final stats = _statsForExercise(exercise);

                                  return Card(
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                      leading: Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.fitness_center_rounded,
                                        ),
                                      ),
                                      title: Text(
                                        exercise.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              exercise.tags.take(3).join(' • '),
                                            ),
                                            const SizedBox(height: 8),
                                            if (stats == null)
                                              Text(
                                                'Sin historial guardado',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white
                                                      .withOpacity(0.70),
                                                ),
                                              )
                                            else
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Última: ${_formatWeight(stats.lastWeight)} kg x ${stats.lastReps}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.white
                                                          .withOpacity(0.70),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'PR: ${_formatWeight(stats.prWeight)} kg x ${stats.prReps}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.white
                                                          .withOpacity(0.70),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ),
                                      onTap: () {
                                        Navigator.pop(context, exercise);
                                      },
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

    if (pickedExercise != null) {
      setState(() {
        _selectedExercises.add(_WorkoutExerciseEntry(exercise: pickedExercise));
      });
    }
  }

  Future<void> _showAddSetDialog(_WorkoutExerciseEntry entry) async {
    final repsController = TextEditingController();
    final weightController = TextEditingController();
    final stats = _statsForExercise(entry.exercise);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Añadir serie - ${entry.exercise.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (stats != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Referencia',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Última vez: ${_formatWeight(stats.lastWeight)} kg x ${stats.lastReps}',
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'PR: ${_formatWeight(stats.prWeight)} kg x ${stats.prReps}',
                        ),
                      ],
                    ),
                  ),
                if (stats != null) const SizedBox(height: 12),
                TextField(
                  controller: repsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Repeticiones',
                    hintText: 'Ejemplo: 10',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Peso (kg)',
                    hintText: 'Ejemplo: 60',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final reps = int.tryParse(repsController.text.trim());
                final weight = double.tryParse(
                  weightController.text.trim().replaceAll(',', '.'),
                );

                if (reps == null || reps <= 0 || weight == null || weight < 0) {
                  return;
                }

                final restForThisSet =
                    entry.sets.isEmpty && !_hasStartedRestTracking
                    ? 0
                    : _currentRestSeconds;

                setState(() {
                  entry.sets.add(
                    _WorkoutSetEntry(
                      setNumber: entry.sets.length + 1,
                      reps: reps,
                      weight: weight,
                      restSeconds: restForThisSet,
                      createdAt: DateTime.now(),
                    ),
                  );
                });

                Navigator.pop(context);
                _restartRestStopwatch();
              },
              child: const Text('Guardar serie'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditSetDialog(
    _WorkoutExerciseEntry entry,
    _WorkoutSetEntry setEntry,
  ) async {
    final repsController = TextEditingController(
      text: setEntry.reps.toString(),
    );
    final weightController = TextEditingController(
      text: setEntry.weight.toString(),
    );
    final restController = TextEditingController(
      text: setEntry.restSeconds.toString(),
    );

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar serie ${setEntry.setNumber}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: repsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Repeticiones'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Peso (kg)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: restController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Descanso guardado (segundos)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final reps = int.tryParse(repsController.text.trim());
                final weight = double.tryParse(
                  weightController.text.trim().replaceAll(',', '.'),
                );
                final rest = int.tryParse(restController.text.trim());

                if (reps == null ||
                    reps <= 0 ||
                    weight == null ||
                    weight < 0 ||
                    rest == null ||
                    rest < 0) {
                  return;
                }

                final index = entry.sets.indexOf(setEntry);
                if (index == -1) return;

                setState(() {
                  entry.sets[index] = _WorkoutSetEntry(
                    setNumber: setEntry.setNumber,
                    reps: reps,
                    weight: weight,
                    restSeconds: rest,
                    createdAt: setEntry.createdAt,
                  );
                });

                Navigator.pop(context);
              },
              child: const Text('Guardar cambios'),
            ),
          ],
        );
      },
    );
  }

  void _duplicateLastSet(_WorkoutExerciseEntry entry) {
    if (entry.sets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero añade una serie manualmente'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final lastSet = entry.sets.last;
    final restForThisSet = _hasStartedRestTracking ? _currentRestSeconds : 0;

    setState(() {
      entry.sets.add(
        _WorkoutSetEntry(
          setNumber: entry.sets.length + 1,
          reps: lastSet.reps,
          weight: lastSet.weight,
          restSeconds: restForThisSet,
          createdAt: DateTime.now(),
        ),
      );
    });

    _restartRestStopwatch();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Serie duplicada en ${entry.exercise.name}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _removeExercise(_WorkoutExerciseEntry entry) {
    setState(() {
      _selectedExercises.remove(entry);
    });
  }

  void _removeSet(_WorkoutExerciseEntry entry, _WorkoutSetEntry setEntry) {
    setState(() {
      entry.sets.remove(setEntry);

      for (int i = 0; i < entry.sets.length; i++) {
        entry.sets[i] = _WorkoutSetEntry(
          setNumber: i + 1,
          reps: entry.sets[i].reps,
          weight: entry.sets[i].weight,
          restSeconds: entry.sets[i].restSeconds,
          createdAt: entry.sets[i].createdAt,
        );
      }
    });
  }

  Future<void> _finishWorkout() async {
    if (_selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Añade al menos un ejercicio al entrenamiento'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_totalSets == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Añade al menos una serie antes de guardar'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final exerciseRecords = _selectedExercises.map((entry) {
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
    }).toList();

    final finishedAt = DateTime.now();

    final session = WorkoutSession(
      id: finishedAt.microsecondsSinceEpoch.toString(),
      routineId: 'free_workout',
      routineName: widget.title,
      startedAt: _startedAt,
      finishedAt: finishedAt,
      durationSeconds: _elapsedSeconds,
      exercises: exerciseRecords,
      totalVolume: _totalVolume,
    );

    final exerciseCount = session.totalExercises;
    final totalSets = session.totalSets;
    final duration = _formatDuration(session.durationSeconds);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Entrenamiento finalizado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SummaryRow(label: 'Sesión', value: session.routineName),
              _SummaryRow(label: 'Ejercicios', value: '$exerciseCount'),
              _SummaryRow(label: 'Series', value: '$totalSets'),
              _SummaryRow(label: 'Duración', value: duration),
              _SummaryRow(
                label: 'Volumen total',
                value: '${session.totalVolume.toStringAsFixed(1)} kg',
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
    );

    if (confirmed != true) return;

    setState(() {
      _isSaving = true;
    });

    await WorkoutStorage.saveSession(session);

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Entrenamiento guardado en historial'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context, true);
  }

  Widget _buildTopStatsCard() {
    final restLabel = _hasStartedRestTracking
        ? '${_currentRestSeconds}s'
        : '--';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E2A44), Color(0xFF203A43)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Entrenamiento en curso',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _TopInfoBox(
                  label: 'Tiempo total',
                  value: _formatDuration(_elapsedSeconds),
                  icon: Icons.timer_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TopInfoBox(
                  label: 'Descanso actual',
                  value: restLabel,
                  icon: Icons.hourglass_bottom_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _TopInfoBox(
                  label: 'Ejercicios',
                  value: '${_selectedExercises.length}',
                  icon: Icons.list_alt_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TopInfoBox(
                  label: 'Series',
                  value: '$_totalSets',
                  icon: Icons.repeat_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(_WorkoutExerciseEntry entry) {
    final hasSets = entry.sets.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.exercise.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _removeExercise(entry),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: entry.exercise.tags.take(4).map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(tag, style: const TextStyle(fontSize: 11)),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: _buildReferenceChips(entry.exercise),
            ),
            const SizedBox(height: 14),
            if (!hasSets)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Todavía no has añadido series',
                  style: TextStyle(color: Colors.white.withOpacity(0.75)),
                ),
              )
            else
              Column(
                children: entry.sets.map((setEntry) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Serie ${setEntry.setNumber}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text('${setEntry.reps} reps'),
                            const SizedBox(width: 14),
                            Text('${setEntry.weight} kg'),
                            const SizedBox(width: 14),
                            Text('${setEntry.restSeconds}s'),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () =>
                                  _showEditSetDialog(entry, setEntry),
                              icon: const Icon(Icons.edit_rounded, size: 18),
                              label: const Text('Editar'),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () => _removeSet(entry, setEntry),
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: const Text('Borrar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: hasSets ? () => _duplicateLastSet(entry) : null,
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Duplicar última'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _showAddSetDialog(entry),
                    icon: const Icon(Icons.add),
                    label: const Text('Añadir serie'),
                  ),
                ),
              ],
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
          IconButton(
            onPressed: _isSaving ? null : _finishWorkout,
            icon: const Icon(Icons.check_circle_outline_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openExercisePicker,
        icon: const Icon(Icons.add),
        label: const Text('Ejercicio'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTopStatsCard(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Ejercicios del entrenamiento',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${_selectedExercises.length} añadidos',
                      style: TextStyle(color: Colors.white.withOpacity(0.75)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _selectedExercises.isEmpty
                      ? Center(
                          child: Text(
                            'Pulsa “Ejercicio” para empezar tu entrenamiento',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.separated(
                          itemCount: _selectedExercises.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
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
