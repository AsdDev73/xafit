import 'package:flutter/material.dart';

class WorkoutTagChipData {
  final IconData icon;
  final String label;

  const WorkoutTagChipData({
    required this.icon,
    required this.label,
  });
}

class WorkoutSetCardData {
  final int setNumber;
  final bool isWarmup;
  final String performanceLabel;
  final String restLabel;
  final String volumeLabel;

  const WorkoutSetCardData({
    required this.setNumber,
    required this.isWarmup,
    required this.performanceLabel,
    required this.restLabel,
    required this.volumeLabel,
  });
}

class WorkoutExerciseCard extends StatelessWidget {
  final String title;
  final List<WorkoutTagChipData> summaryTags;
  final List<WorkoutTagChipData> referenceTags;
  final List<WorkoutSetCardData> setCards;
  final VoidCallback onAddSet;
  final VoidCallback? onDuplicateLastSet;
  final VoidCallback onRemoveExercise;
  final ValueChanged<int> onEditSet;
  final ValueChanged<int> onDeleteSet;
  final Widget? dragHandle;

  const WorkoutExerciseCard({
    super.key,
    required this.title,
    required this.summaryTags,
    required this.referenceTags,
    required this.setCards,
    required this.onAddSet,
    required this.onDuplicateLastSet,
    required this.onRemoveExercise,
    required this.onEditSet,
    required this.onDeleteSet,
    this.dragHandle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ExerciseCardHeader(
              title: title,
              summaryTags: summaryTags,
              onAddSet: onAddSet,
              onDuplicateLastSet: onDuplicateLastSet,
              onRemoveExercise: onRemoveExercise,
              dragHandle: dragHandle,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in referenceTags)
                  _WorkoutMiniTagChip(icon: tag.icon, label: tag.label),
              ],
            ),
            const SizedBox(height: 14),
            if (setCards.isEmpty)
              _WorkoutExerciseEmptyState(onAddSet: onAddSet)
            else
              Column(
                children: [
                  for (int i = 0; i < setCards.length; i++)
                    _WorkoutSetCard(
                      data: setCards[i],
                      onEdit: () => onEditSet(i),
                      onDelete: () => onDeleteSet(i),
                    ),
                ],
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAddSet,
                    icon: const Icon(Icons.add),
                    label: const Text('Nueva serie'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onDuplicateLastSet,
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
}

class _ExerciseCardHeader extends StatelessWidget {
  final String title;
  final List<WorkoutTagChipData> summaryTags;
  final VoidCallback onAddSet;
  final VoidCallback? onDuplicateLastSet;
  final VoidCallback onRemoveExercise;
  final Widget? dragHandle;

  const _ExerciseCardHeader({
    required this.title,
    required this.summaryTags,
    required this.onAddSet,
    required this.onDuplicateLastSet,
    required this.onRemoveExercise,
    this.dragHandle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
                title,
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
                  for (final tag in summaryTags)
                    _WorkoutMiniTagChip(icon: tag.icon, label: tag.label),
                ],
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'addSet') {
              onAddSet();
            } else if (value == 'duplicate') {
              final action = onDuplicateLastSet;
              if (action != null) action();
            } else if (value == 'removeExercise') {
              onRemoveExercise();
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
        if (dragHandle != null) dragHandle!,
      ],
    );
  }
}

class _WorkoutExerciseEmptyState extends StatelessWidget {
  final VoidCallback onAddSet;

  const _WorkoutExerciseEmptyState({required this.onAddSet});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            onPressed: onAddSet,
            icon: const Icon(Icons.add),
            label: const Text('Añadir primera serie'),
          ),
        ],
      ),
    );
  }
}

class _WorkoutSetCard extends StatelessWidget {
  final WorkoutSetCardData data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _WorkoutSetCard({
    required this.data,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isWarmup = data.isWarmup;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isWarmup
            ? const Color(0xFFFFB74D).withValues(alpha: 0.08)
            : const Color(0xFF1C2330),
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
                '${data.setNumber}',
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
                  data.performanceLabel,
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
                    _WorkoutMiniTagChip(
                      icon: isWarmup
                          ? Icons.wb_sunny_outlined
                          : Icons.local_fire_department_outlined,
                      label: isWarmup ? 'Calentamiento' : 'Serie efectiva',
                    ),
                    _WorkoutMiniTagChip(
                      icon: Icons.timelapse_rounded,
                      label: data.restLabel,
                    ),
                    _WorkoutMiniTagChip(
                      icon: Icons.fitness_center_rounded,
                      label: data.volumeLabel,
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
                onEdit();
              } else if (value == 'delete') {
                onDelete();
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
}

class _WorkoutMiniTagChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _WorkoutMiniTagChip({
    required this.icon,
    required this.label,
  });

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
