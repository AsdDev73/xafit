part of '../../screens/workout_screen.dart';

class _FinishWorkoutDecision {
  final String? notes;

  const _FinishWorkoutDecision({required this.notes});
}

class _FinishWorkoutDialog extends StatefulWidget {
  const _FinishWorkoutDialog();

  @override
  State<_FinishWorkoutDialog> createState() => _FinishWorkoutDialogState();
}

class _FinishWorkoutDialogState extends State<_FinishWorkoutDialog> {
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Finalizar entrenamiento'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Puedes añadir una nota opcional para recordar sensaciones, molestias o ajustes para la próxima vez.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _notesController,
              maxLines: 4,
              maxLength: 240,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText:
                    'Ej: hoy iba cansado, subir 2,5 kg en press, molestia en hombro...',
                labelText: 'Nota del entrenamiento',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(
            const _FinishWorkoutDecision(notes: null),
          ),
          child: const Text('Sin nota'),
        ),
        FilledButton(
          onPressed: () {
            final rawNotes = _notesController.text.trim();
            Navigator.of(context).pop(
              _FinishWorkoutDecision(
                notes: rawNotes.isEmpty ? null : rawNotes,
              ),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

enum _WorkoutPersonalRecordType { weight, reps, volume }

class _WorkoutPersonalRecordAchievement {
  final String exerciseId;
  final String exerciseName;
  final _WorkoutPersonalRecordType type;
  final double weight;
  final int reps;

  const _WorkoutPersonalRecordAchievement({
    required this.exerciseId,
    required this.exerciseName,
    required this.type,
    required this.weight,
    required this.reps,
  });

  double get volume => weight * reps;

  String typeLabel() {
    switch (type) {
      case _WorkoutPersonalRecordType.weight:
        return 'PR de peso';
      case _WorkoutPersonalRecordType.reps:
        return 'PR de reps';
      case _WorkoutPersonalRecordType.volume:
        return 'PR de volumen';
    }
  }

  String valueLabel(String Function(double value) formatWeight) {
    switch (type) {
      case _WorkoutPersonalRecordType.weight:
        return '${formatWeight(weight)} × $reps reps';
      case _WorkoutPersonalRecordType.reps:
        return '$reps reps con ${formatWeight(weight)}';
      case _WorkoutPersonalRecordType.volume:
        return '${formatWeight(weight)} × $reps • ${formatWeight(volume)}';
    }
  }
}

class _PersonalRecordDialogTile extends StatelessWidget {
  final _WorkoutPersonalRecordAchievement achievement;
  final String Function(double value) formatWeight;

  const _PersonalRecordDialogTile({
    required this.achievement,
    required this.formatWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.emoji_events_outlined,
              color: Colors.amber,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.exerciseName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        achievement.typeLabel(),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  achievement.valueLabel(formatWeight),
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.white.withValues(alpha: 0.78),
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

