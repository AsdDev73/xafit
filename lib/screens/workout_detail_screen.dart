import 'package:flutter/material.dart';

import '../models/workout_session.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final WorkoutSession session;

  const WorkoutDetailScreen({super.key, required this.session});

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year - $hour:$minute';
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

  Widget _buildInfoCard(String label, String value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.75),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSetRow(WorkoutSetRecord set) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Serie ${set.setNumber}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text('${set.reps} reps'),
          const SizedBox(width: 14),
          Text('${set.weight} kg'),
          const SizedBox(width: 14),
          Text('${set.restSeconds}s'),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(WorkoutExerciseRecord exercise) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                exercise.exerciseName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: exercise.tags.take(5).map((tag) {
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
            const SizedBox(height: 14),
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
      appBar: AppBar(title: Text(session.routineName)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
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
                    session.routineName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(dateText, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoCard('Ejercicios', '${session.totalExercises}'),
                const SizedBox(width: 10),
                _buildInfoCard('Series', '${session.totalSets}'),
                const SizedBox(width: 10),
                _buildInfoCard(
                  'Duración',
                  _formatDuration(session.durationSeconds),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildInfoCard(
                  'Volumen total',
                  '${session.totalVolume.toStringAsFixed(1)} kg',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: session.exercises.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildExerciseCard(session.exercises[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
