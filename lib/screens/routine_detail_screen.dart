import 'package:flutter/material.dart';

import '../data/exercise_catalog.dart';
import '../models/exercise.dart';
import '../models/routine.dart';
import '../repositories/custom_exercise_repository.dart';
import '../services/app_repositories.dart';
import '../services/favorite_exercises_service.dart';
import 'workout_screen.dart';

class RoutineDetailScreen extends StatefulWidget {
  final Routine routine;

  const RoutineDetailScreen({super.key, required this.routine});

  @override
  State<RoutineDetailScreen> createState() => _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends State<RoutineDetailScreen> {
  final CustomExerciseRepository _customExerciseRepository =
      AppRepositories.customExercises;
  final FavoriteExercisesService _favoriteExercisesService =
      const FavoriteExercisesService();

  final TextEditingController _searchController = TextEditingController();

  final List<Exercise> _customExercises = [];

  bool _isLoadingCustomExercises = true;
  bool _isLoadingFavorites = true;

  String _searchText = '';
  String? _selectedTag;
  bool _showFavoritesOnly = false;

  Set<String> _favoriteIds = <String>{};

  List<Exercise> get _allExercises => [
    ...ExerciseCatalog.byMuscleGroup(widget.routine.muscleGroup),
    ..._customExercises,
  ];

  List<String> get _availableTags {
    final tags = <String>{};

    for (final exercise in _allExercises) {
      tags.addAll(exercise.tags.map((tag) => tag.toString()));
    }

    final result = tags.toList()..sort();
    return result;
  }

  List<Exercise> get _favoriteExercisesInGroup {
    final favorites = _allExercises
        .where((exercise) => _favoriteIds.contains(exercise.id))
        .toList();

    favorites.sort(_compareExercises);
    return favorites;
  }

  int get _favoriteCountInGroup => _favoriteExercisesInGroup.length;

  List<Exercise> get _filteredExercises {
    final query = _normalizeText(_searchText.trim());

    final filtered = _allExercises.where((exercise) {
      final matchesSearch =
          query.isEmpty ||
          _normalizeText(exercise.name).contains(query) ||
          exercise.tags.any(
            (tag) => _normalizeText(tag.toString()).contains(query),
          );

      final matchesTag =
          _selectedTag == null || exercise.tags.contains(_selectedTag);

      final matchesFavorites =
          !_showFavoritesOnly || _favoriteIds.contains(exercise.id);

      return matchesSearch && matchesTag && matchesFavorites;
    }).toList();

    filtered.sort(_compareExercises);
    return filtered;
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_loadCustomExercises(), _loadFavorites()]);
  }

  Future<void> _loadCustomExercises() async {
    final customExercises = await _customExerciseRepository.getByMuscleGroup(
      widget.routine.muscleGroup,
    );

    if (!mounted) return;

    setState(() {
      _customExercises
        ..clear()
        ..addAll(customExercises);
      _isLoadingCustomExercises = false;
    });
  }

  Future<void> _loadFavorites() async {
    final favoriteIds = await _favoriteExercisesService.getFavoriteIds();

    if (!mounted) return;

    setState(() {
      _favoriteIds = favoriteIds;
      _isLoadingFavorites = false;
    });
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

  void _showFloatingSnackBar(String message) {
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

    _showFloatingSnackBar(
      isNowFavorite
          ? '${exercise.name} añadido a favoritos'
          : '${exercise.name} eliminado de favoritos',
    );
  }

  Future<void> _addCustomExercise() async {
    final result = await _showCustomExerciseDialog();
    if (result == null) return;

    await _customExerciseRepository.saveCustomExercise(result);
    await _loadCustomExercises();

    if (!mounted) return;
    _showFloatingSnackBar('${result.name} añadido a ${widget.routine.name}');
  }

  Future<void> _editCustomExercise(Exercise exercise) async {
    final result = await _showCustomExerciseDialog(existing: exercise);
    if (result == null) return;

    await _customExerciseRepository.saveCustomExercise(result);
    await _loadCustomExercises();

    if (!mounted) return;
    _showFloatingSnackBar('${result.name} actualizado');
  }

  Future<Exercise?> _showCustomExerciseDialog({Exercise? existing}) async {
    final existingNames = _allExercises
        .where((exercise) => exercise.id != existing?.id)
        .map((exercise) => exercise.name.trim().toLowerCase())
        .toSet();

    return showDialog<Exercise>(
      context: context,
      builder: (_) => _CustomExerciseDialog(
        muscleGroup: widget.routine.muscleGroup,
        existing: existing,
        existingNames: existingNames,
      ),
    );
  }

  Future<void> _deleteCustomExercise(Exercise exercise) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Eliminar ejercicio personalizado'),
              content: Text(
                'Se eliminará ${exercise.name} de tu biblioteca personalizada.\n\n'
                'Los entrenamientos ya guardados no se borrarán.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Eliminar'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) return;

    await _customExerciseRepository.deleteCustomExercise(exercise.id);
    await _favoriteExercisesService.setFavorite(exercise.id, false);
    await Future.wait([_loadCustomExercises(), _loadFavorites()]);

    if (!mounted) return;
    _showFloatingSnackBar('${exercise.name} eliminado');
  }

  Future<void> _startWorkoutWithExercises({
    required String title,
    required List<Exercise> exercises,
  }) async {
    if (exercises.isEmpty) {
      _showFloatingSnackBar('No hay ejercicios disponibles para ese filtro');
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            WorkoutScreen(title: title, availableExercises: exercises),
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    final isSelected = _selectedTag == tag;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(tag),
        onSelected: (_) {
          setState(() {
            _selectedTag = isSelected ? null : tag;
          });
        },
      ),
    );
  }

  Widget _buildStatusChip({
    required String label,
    required Color color,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildExerciseCard(Exercise exercise) {
    final isFavorite = _favoriteIds.contains(exercise.id);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          exercise.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: isFavorite
                            ? 'Quitar de favoritos'
                            : 'Añadir a favoritos',
                        onPressed: () => _toggleFavorite(exercise),
                        icon: Icon(
                          isFavorite
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: isFavorite ? Colors.amber : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    exercise.muscleGroup,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.70),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: exercise.tags.take(6).map((tag) {
                      final label = tag.toString();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(fontSize: 11),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildStatusChip(
                        label: exercise.isCustom ? 'Custom' : 'Base',
                        color: exercise.isCustom
                            ? Colors.orangeAccent
                            : Colors.lightBlueAccent,
                        background: exercise.isCustom
                            ? Colors.orange.withValues(alpha: 0.18)
                            : Colors.blue.withValues(alpha: 0.18),
                      ),
                      if (isFavorite)
                        _buildStatusChip(
                          label: 'Favorito',
                          color: Colors.amber,
                          background: Colors.amber.withValues(alpha: 0.15),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (exercise.isCustom)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _editCustomExercise(exercise);
                  } else if (value == 'delete') {
                    _deleteCustomExercise(exercise);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercises = _filteredExercises;
    final availableTags = _availableTags;
    final isLoading = _isLoadingCustomExercises || _isLoadingFavorites;

    return Scaffold(
      appBar: AppBar(title: Text(widget.routine.name)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCustomExercise,
        icon: const Icon(Icons.add),
        label: const Text('Personalizado'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
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
                          widget.routine.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.routine.description,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _HeroPill(
                              icon: Icons.fitness_center_rounded,
                              label: '${_allExercises.length} ejercicios',
                            ),
                            _HeroPill(
                              icon: Icons.star_rounded,
                              label: '$_favoriteCountInGroup favoritos',
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => _startWorkoutWithExercises(
                              title: 'Entreno ${widget.routine.name}',
                              exercises: _allExercises,
                            ),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Entrenar solo este grupo'),
                          ),
                        ),
                        if (_favoriteExercisesInGroup.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _startWorkoutWithExercises(
                                title: 'Favoritos ${widget.routine.name}',
                                exercises: _favoriteExercisesInGroup,
                              ),
                              icon: const Icon(Icons.star_rounded),
                              label: const Text('Entrenar favoritos del grupo'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchText = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Buscar ejercicio o tag...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchText.trim().isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchText = '';
                                });
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
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
                            selected: !_showFavoritesOnly,
                            label: const Text('Todos'),
                            onSelected: (_) {
                              setState(() {
                                _showFavoritesOnly = false;
                              });
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            selected: _showFavoritesOnly,
                            label: Text('Favoritos ($_favoriteCountInGroup)'),
                            onSelected: (_) {
                              setState(() {
                                _showFavoritesOnly = true;
                              });
                            },
                          ),
                        ),
                        ...availableTags.map(_buildTagChip),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${exercises.length} resultados',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: exercises.isEmpty
                        ? Center(
                            child: Text(
                              _showFavoritesOnly
                                  ? 'No hay favoritos que coincidan con tu búsqueda'
                                  : 'No hay ejercicios que coincidan con tu búsqueda',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: exercises.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final exercise = exercises[index];
                              return _buildExerciseCard(exercise);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroPill({required this.icon, required this.label});

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

class _CustomExerciseDialog extends StatefulWidget {
  final String muscleGroup;
  final Exercise? existing;
  final Set<String> existingNames;

  const _CustomExerciseDialog({
    required this.muscleGroup,
    required this.existing,
    required this.existingNames,
  });

  @override
  State<_CustomExerciseDialog> createState() => _CustomExerciseDialogState();
}

class _CustomExerciseDialogState extends State<_CustomExerciseDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _tagsController;

  String? _errorText;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _tagsController = TextEditingController(
      text: widget.existing == null
          ? ''
          : widget.existing!.tags.map((tag) => tag.toString()).join(', '),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  List<String> _parseTags(String rawTags) {
    final tags =
        rawTags
            .split(',')
            .map((tag) => tag.trim().toLowerCase())
            .where((tag) => tag.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    if (tags.isEmpty) {
      return ['personalizado'];
    }

    return tags;
  }

  void _save() {
    FocusScope.of(context).unfocus();

    final name = _nameController.text.trim();
    final normalizedName = name.toLowerCase();

    if (name.isEmpty) {
      setState(() {
        _errorText = 'Escribe un nombre para el ejercicio';
      });
      return;
    }

    if (widget.existingNames.contains(normalizedName)) {
      setState(() {
        _errorText = 'Ya existe un ejercicio con ese nombre';
      });
      return;
    }

    final exercise = Exercise(
      id:
          widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      muscleGroup: widget.muscleGroup,
      tags: _parseTags(_tagsController.text),
      isCustom: true,
    );

    Navigator.of(context).pop(exercise);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return AlertDialog(
      title: Text(
        isEditing
            ? 'Editar ejercicio personalizado'
            : 'Añadir ejercicio personalizado',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Nombre',
                hintText: 'Ejemplo: Press convergente',
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
            const SizedBox(height: 12),
            TextField(
              controller: _tagsController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Tags',
                hintText: 'Ejemplo: maquina, compuesto, pecho superior',
              ),
              onSubmitted: (_) => _save(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(isEditing ? 'Guardar' : 'Añadir'),
        ),
      ],
    );
  }
}
