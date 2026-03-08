import 'package:flutter/material.dart';

import '../data/exercise_catalog.dart';
import '../data/routine_seed.dart';
import '../models/routine.dart';
import 'routine_detail_screen.dart';

class RoutinesScreen extends StatelessWidget {
  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Biblioteca')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.separated(
          itemCount: defaultRoutines.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final routine = defaultRoutines[index];
            final exerciseCount = ExerciseCatalog.byMuscleGroup(
              routine.muscleGroup,
            ).length;

            return _RoutineCard(routine: routine, exerciseCount: exerciseCount);
          },
        ),
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  final Routine routine;
  final int exerciseCount;

  const _RoutineCard({required this.routine, required this.exerciseCount});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RoutineDetailScreen(routine: routine),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.folder_special_rounded, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routine.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      routine.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.70),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$exerciseCount ejercicios disponibles',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.lightBlueAccent.shade100,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 30),
            ],
          ),
        ),
      ),
    );
  }
}
