import 'package:flutter/material.dart';

import '../data/exercise_catalog.dart';
import '../data/routine_seed.dart';
import '../models/routine.dart';
import '../services/favorite_exercises_service.dart';
import 'routine_detail_screen.dart';

class RoutinesScreen extends StatefulWidget {
  const RoutinesScreen({super.key});

  @override
  State<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends State<RoutinesScreen> {
  final FavoriteExercisesService _favoriteExercisesService =
      const FavoriteExercisesService();

  Set<String> _favoriteIds = <String>{};
  bool _isLoadingFavorites = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favoriteIds = await _favoriteExercisesService.getFavoriteIds();

    if (!mounted) return;
    setState(() {
      _favoriteIds = favoriteIds;
      _isLoadingFavorites = false;
    });
  }

  Future<void> _openRoutineDetail(Routine routine) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RoutineDetailScreen(routine: routine)),
    );

    if (!mounted) return;
    await _loadFavorites();
  }

  int _favoriteCountForGroup(String muscleGroup) {
    final exercises = ExerciseCatalog.byMuscleGroup(muscleGroup);
    return exercises
        .where((exercise) => _favoriteIds.contains(exercise.id))
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final totalFavorites = _favoriteIds.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Biblioteca')),
      body: _isLoadingFavorites
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E2A44), Color(0xFF203A43)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Biblioteca de ejercicios',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Explora ejercicios por grupo muscular y guarda favoritos para encontrarlos más rápido.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoPill(
                              icon: Icons.folder_special_rounded,
                              label: '${defaultRoutines.length} grupos',
                            ),
                            _InfoPill(
                              icon: Icons.fitness_center_rounded,
                              label:
                                  '${ExerciseCatalog.totalCount} ejercicios base',
                            ),
                            _InfoPill(
                              icon: Icons.star_rounded,
                              label: '$totalFavorites favoritos',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(defaultRoutines.length, (index) {
                    final routine = defaultRoutines[index];
                    final exerciseCount = ExerciseCatalog.byMuscleGroup(
                      routine.muscleGroup,
                    ).length;
                    final favoriteCount = _favoriteCountForGroup(
                      routine.muscleGroup,
                    );

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == defaultRoutines.length - 1 ? 0 : 12,
                      ),
                      child: _RoutineCard(
                        routine: routine,
                        exerciseCount: exerciseCount,
                        favoriteCount: favoriteCount,
                        onTap: () => _openRoutineDetail(routine),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  final Routine routine;
  final int exerciseCount;
  final int favoriteCount;
  final VoidCallback onTap;

  const _RoutineCard({
    required this.routine,
    required this.exerciseCount,
    required this.favoriteCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
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
                        color: Colors.white.withValues(alpha: 0.70),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MiniPill(
                          icon: Icons.fitness_center_rounded,
                          label: '$exerciseCount ejercicios',
                        ),
                        _MiniPill(
                          icon: Icons.star_rounded,
                          label: '$favoriteCount favoritos',
                        ),
                      ],
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

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white70),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
