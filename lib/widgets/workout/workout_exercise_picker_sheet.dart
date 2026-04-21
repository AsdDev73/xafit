part of '../../screens/workout_screen.dart';

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
    final groups = _availableExercisesExcludingSelected
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
      final matchesQuery = query.isEmpty ||
          exercise.name.toLowerCase().contains(query) ||
          exercise.muscleGroup.toLowerCase().contains(query) ||
          exercise.tags.any((tag) => tag.toLowerCase().contains(query));

      final matchesGroup = _selectedMuscleGroup == null ||
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
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final exercise = exercises[index];
                            final isFavorite =
                                _favoriteIds.contains(exercise.id);

                            return Material(
                              color: Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(18),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () =>
                                    Navigator.of(context).pop(exercise),
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
                                          borderRadius:
                                              BorderRadius.circular(12),
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
                                                      fontWeight:
                                                          FontWeight.w700,
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
                                                        : Icons
                                                            .star_border_rounded,
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
                                                ...exercise.tags.take(3).map(
                                                      (tag) => _MiniTagChip(
                                                        icon:
                                                            Icons.sell_outlined,
                                                        label: tag,
                                                      ),
                                                    ),
                                                _MiniTagChip(
                                                  icon: exercise.isCustom
                                                      ? Icons
                                                          .auto_fix_high_rounded
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
