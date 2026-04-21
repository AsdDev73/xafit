import 'package:flutter/material.dart';

class WorkoutHeaderPanel extends StatelessWidget {
  final String title;
  final String elapsedLabel;
  final String exerciseCountLabel;
  final String totalSetsLabel;
  final String totalWorkingSetsLabel;
  final String totalWarmupSetsLabel;
  final String totalVolumeLabel;
  final String restLabel;

  const WorkoutHeaderPanel({
    super.key,
    required this.title,
    required this.elapsedLabel,
    required this.exerciseCountLabel,
    required this.totalSetsLabel,
    required this.totalWorkingSetsLabel,
    required this.totalWarmupSetsLabel,
    required this.totalVolumeLabel,
    required this.restLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF172235), Color(0xFF1D3A45)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Entrenamiento libre',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
              _WorkoutTimeBadge(elapsedLabel: elapsedLabel),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _WorkoutSummaryChip(
                icon: Icons.fitness_center_rounded,
                label: 'Ejercicios',
                value: exerciseCountLabel,
              ),
              _WorkoutSummaryChip(
                icon: Icons.layers_outlined,
                label: 'Series',
                value: totalSetsLabel,
              ),
              _WorkoutSummaryChip(
                icon: Icons.local_fire_department_outlined,
                label: 'Efectivas',
                value: totalWorkingSetsLabel,
              ),
              _WorkoutSummaryChip(
                icon: Icons.wb_sunny_outlined,
                label: 'Calent.',
                value: totalWarmupSetsLabel,
              ),
              _WorkoutSummaryChip(
                icon: Icons.monitor_weight_outlined,
                label: 'Volumen',
                value: totalVolumeLabel,
              ),
              _WorkoutSummaryChip(
                icon: Icons.timer_outlined,
                label: 'Descanso',
                value: restLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WorkoutActionBar extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onAddExercise;
  final VoidCallback onFinish;

  const WorkoutActionBar({
    super.key,
    required this.isSaving,
    required this.onAddExercise,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onAddExercise,
            icon: const Icon(Icons.add),
            label: const Text('Añadir ejercicio'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isSaving ? null : onFinish,
            icon: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline_rounded),
            label: Text(isSaving ? 'Guardando...' : 'Finalizar'),
          ),
        ),
      ],
    );
  }
}

class WorkoutEmptyStateCard extends StatelessWidget {
  final VoidCallback onAddExercise;

  const WorkoutEmptyStateCard({
    super.key,
    required this.onAddExercise,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF171C25),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.fitness_center_rounded, size: 34),
          ),
          const SizedBox(height: 16),
          const Text(
            'Empieza tu entrenamiento',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Añade ejercicios y registra series con peso, repeticiones y descanso automático.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.74),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onAddExercise,
            icon: const Icon(Icons.add),
            label: const Text('Añadir primer ejercicio'),
          ),
        ],
      ),
    );
  }
}

class WorkoutReorderHintCard extends StatelessWidget {
  const WorkoutReorderHintCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2330),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Colors.white.withValues(alpha: 0.78),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mantén el icono de arrastre para reordenar ejercicios.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutTimeBadge extends StatelessWidget {
  final String elapsedLabel;

  const _WorkoutTimeBadge({required this.elapsedLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tiempo',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            elapsedLabel,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutSummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _WorkoutSummaryChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
