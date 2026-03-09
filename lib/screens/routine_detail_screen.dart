import 'package:flutter/material.dart';

import '../data/exercise_catalog.dart';
import '../models/exercise.dart';
import '../models/routine.dart';
import '../repositories/custom_exercise_repository.dart';
import '../services/app_repositories.dart';
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
  final TextEditingController _searchController = TextEditingController();

  final List<Exercise> _customExercises = [];

  bool _isLoadingCustomExercises = true;
  String _searchText = '';
  String? _selectedTag;

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

  List<Exercise> get _filteredExercises {
    final query = _searchText.trim().toLowerCase();

    return _allExercises.where((exercise) {
      final matchesSearch =
          query.isEmpty ||
          exercise.name.toLowerCase().contains(query) ||
          exercise.tags.any(
            (tag) => tag.toString().toLowerCase().contains(query),
          );

      final matchesTag =
          _selectedTag == null ||
          exercise.tags.map((tag) => tag.toString()).contains(_selectedTag);

      return matchesSearch && matchesTag;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadCustomExercises();
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
          builder: (context) {
            return AlertDialog(
              title: const Text('Eliminar ejercicio personalizado'),
              content: Text(
                'Se eliminará ${exercise.name} de tu biblioteca personalizada.\n\n'
                'Los entrenamientos ya guardados no se borrarán.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Eliminar'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) return;

    await _customExerciseRepository.deleteCustomExercise(exercise.id);
    await _loadCustomExercises();

    if (!mounted) return;
    _showFloatingSnackBar('${exercise.name} eliminado');
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

  Widget _buildExerciseCard(Exercise exercise) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.sports_gymnastics_rounded),
        ),
        title: Text(
          exercise.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(exercise.muscleGroup),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: exercise.tags.take(4).map((tag) {
                  final label = tag.toString();

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(label, style: const TextStyle(fontSize: 11)),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: exercise.isCustom
                    ? Colors.orange.withOpacity(0.18)
                    : Colors.blue.withOpacity(0.18),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                exercise.isCustom ? 'Custom' : 'Base',
                style: TextStyle(
                  fontSize: 12,
                  color: exercise.isCustom
                      ? Colors.orangeAccent
                      : Colors.lightBlueAccent,
                ),
              ),
            ),
            if (exercise.isCustom) ...[
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Editar personalizado',
                onPressed: () => _editCustomExercise(exercise),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Eliminar personalizado',
                onPressed: () => _deleteCustomExercise(exercise),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
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

    return Scaffold(
      appBar: AppBar(title: Text(widget.routine.name)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCustomExercise,
        icon: const Icon(Icons.add),
        label: const Text('Personalizado'),
      ),
      body: _isLoadingCustomExercises
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
                        Text(
                          '${_allExercises.length} ejercicios disponibles',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => WorkoutScreen(
                                    title: 'Entreno ${widget.routine.name}',
                                    availableExercises: _allExercises,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Entrenar solo este grupo'),
                          ),
                        ),
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
                      filled: true,
                      fillColor: const Color(0xFF1A1F2B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
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
                            selected: _selectedTag == null,
                            label: const Text('Todos'),
                            onSelected: (_) {
                              setState(() {
                                _selectedTag = null;
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
                        color: Colors.white.withOpacity(0.75),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: exercises.isEmpty
                        ? Center(
                            child: Text(
                              'No hay ejercicios que coincidan con tu búsqueda',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
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
