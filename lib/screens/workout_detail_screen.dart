import 'package:flutter/material.dart';

import '../models/workout_session.dart';
import '../repositories/workout_repository.dart';
import '../services/app_repositories.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final WorkoutSession session;

  WorkoutDetailScreen({super.key, required this.session});

  final WorkoutRepository _workoutRepository = AppRepositories.workouts;

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year • $hour:$minute';
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

  String _formatRest(int seconds) {
    if (seconds < 60) return '${seconds}s';

    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    if (remainingSeconds == 0) {
      return '${minutes}m';
    }

    return '${minutes}m ${remainingSeconds}s';
  }

  String _displayTag(String tag) {
    switch (tag) {
      case 'pecho':
        return 'Pecho';
      case 'espalda':
        return 'Espalda';
      case 'hombro':
        return 'Hombro';
      case 'biceps':
        return 'Bíceps';
      case 'triceps':
        return 'Tríceps';
      case 'pierna':
        return 'Pierna';
      case 'abdomen':
        return 'Abdomen';
      default:
        if (tag.isEmpty) return tag;
        return tag[0].toUpperCase() + tag.substring(1);
    }
  }

  double _exerciseVolume(WorkoutExerciseRecord exercise) {
    return exercise.sets.fold<double>(
      0,
      (total, set) => total + (set.weight * set.reps),
    );
  }

  Future<void> _deleteSession(BuildContext context) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Eliminar entrenamiento'),
              content: const Text(
                'Se borrará este entrenamiento del historial.',
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

    await _workoutRepository.deleteSession(session.id);

    if (!context.mounted) return;
    Navigator.pop(context, true);
  }

  Widget _buildTopMetric({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.72),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFFFFB74D).withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: highlight
            ? Border.all(color: const Color(0xFFFFB74D).withValues(alpha: 0.30))
            : null,
      ),
      child: Text(text, style: const TextStyle(fontSize: 11.5)),
    );
  }

  Widget _buildSetTypeChip(WorkoutSetRecord set) {
    return _buildTag(
      set.isWarmup ? 'Calentamiento' : 'Efectiva',
      highlight: set.isWarmup,
    );
  }

  Widget _buildSetRow(WorkoutSetRecord set) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: set.isWarmup
            ? const Color(0xFFFFB74D).withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: set.isWarmup
              ? const Color(0xFFFFB74D).withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildSetTypeChip(set),
              const Spacer(),
              Text(
                'Volumen ${_formatWeight(set.weight * set.reps)} kg',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _SetMetricCell(value: '#${set.setNumber}', label: 'Serie'),
              ),
              Expanded(
                flex: 3,
                child: _SetMetricCell(value: '${set.reps}', label: 'Reps'),
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
                  value: _formatRest(set.restSeconds),
                  label: 'Descanso',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(WorkoutExerciseRecord exercise) {
    final volume = _exerciseVolume(exercise);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise.exerciseName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              exercise.muscleGroup,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTag('${exercise.sets.length} series'),
                _buildTag('${exercise.workingSetsCount} efectivas'),
                if (exercise.warmupSetsCount > 0)
                  _buildTag(
                    '${exercise.warmupSetsCount} calentamiento',
                    highlight: true,
                  ),
                _buildTag('${_formatWeight(volume)} kg'),
                ...exercise.tags.take(4).map(_buildTag),
              ],
            ),
            const SizedBox(height: 16),
            Column(children: exercise.sets.map(_buildSetRow).toList()),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateText = _formatDate(session.startedAt);

    return Scaffold(
      appBar: AppBar(
        title: Text(session.routineName),
        actions: [
          IconButton(
            onPressed: () => _deleteSession(context),
            tooltip: 'Eliminar entrenamiento',
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E2A44), Color(0xFF203A43)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.routineName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dateText,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.90),
                  ),
                ),
                if (session.sessionTags.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: session.sessionTags
                        .map((tag) => _buildTag(_displayTag(tag)))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    _buildTopMetric(
                      label: 'Ejercicios',
                      value: '${session.totalExercises}',
                      icon: Icons.fitness_center_rounded,
                    ),
                    const SizedBox(width: 10),
                    _buildTopMetric(
                      label: 'Series',
                      value: '${session.totalSets}',
                      icon: Icons.format_list_numbered_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildTopMetric(
                      label: 'Efectivas',
                      value: '${session.totalWorkingSets}',
                      icon: Icons.local_fire_department_outlined,
                    ),
                    const SizedBox(width: 10),
                    _buildTopMetric(
                      label: 'Calentamiento',
                      value: '${session.totalWarmupSets}',
                      icon: Icons.wb_sunny_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildTopMetric(
                      label: 'Duración',
                      value: _formatDuration(session.durationSeconds),
                      icon: Icons.timer_outlined,
                    ),
                    const SizedBox(width: 10),
                    _buildTopMetric(
                      label: 'Volumen',
                      value: '${_formatWeight(session.totalVolume)} kg',
                      icon: Icons.bar_chart_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Ejercicios registrados',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...session.exercises.map(
            (exercise) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildExerciseCard(exercise),
            ),
          ),
        ],
      ),
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
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.72),
          ),
        ),
      ],
    );
  }
}
