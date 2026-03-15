import '../models/body_profile.dart';
import '../models/body_progress_entry.dart';
import '../models/workout_session.dart';
import '../repositories/body_profile_repository.dart';
import '../repositories/body_progress_repository.dart';
import '../repositories/workout_repository.dart';

class DashboardOverview {
  final int totalSessions;
  final int weeklySessions;
  final double weeklyVolume;
  final double? currentWeight;
  final WorkoutSession? lastSession;
  final BodyProgressEntry? latestProgressEntry;
  final BodyProfile profile;
  final List<DashboardActivityItem> recentActivities;
  final List<DashboardPersonalRecordItem> recentPrs;

  const DashboardOverview({
    required this.totalSessions,
    required this.weeklySessions,
    required this.weeklyVolume,
    required this.currentWeight,
    required this.lastSession,
    required this.latestProgressEntry,
    required this.profile,
    required this.recentActivities,
    required this.recentPrs,
  });

  const DashboardOverview.empty()
    : totalSessions = 0,
      weeklySessions = 0,
      weeklyVolume = 0,
      currentWeight = null,
      lastSession = null,
      latestProgressEntry = null,
      profile = BodyProfile.empty,
      recentActivities = const [],
      recentPrs = const [];
}

class DashboardActivityItem {
  final String id;
  final String title;
  final String subtitle;
  final int sortOrder;

  const DashboardActivityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.sortOrder,
  });
}

class DashboardPersonalRecordItem {
  final String exerciseId;
  final String exerciseName;
  final double weight;
  final int reps;
  final DateTime occurredAt;

  const DashboardPersonalRecordItem({
    required this.exerciseId,
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.occurredAt,
  });
}

class DashboardService {
  final WorkoutRepository workoutRepository;
  final BodyProfileRepository bodyProfileRepository;
  final BodyProgressRepository bodyProgressRepository;

  const DashboardService({
    required this.workoutRepository,
    required this.bodyProfileRepository,
    required this.bodyProgressRepository,
  });

  Future<DashboardOverview> loadOverview() async {
    final rawSessions = await workoutRepository.getAllSessions();
    final rawProgressEntries = await bodyProgressRepository.getEntries();
    final profile = await bodyProfileRepository.getProfile();

    final sessions = List<WorkoutSession>.from(rawSessions)
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

    final progressEntries = List<BodyProgressEntry>.from(rawProgressEntries)
      ..sort((a, b) => b.date.compareTo(a.date));

    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));

    final sessionsThisWeek = sessions.where((session) {
      final sessionDate = DateTime(
        session.startedAt.year,
        session.startedAt.month,
        session.startedAt.day,
      );
      return !sessionDate.isBefore(startOfWeek);
    }).toList();

    double weeklyVolume = 0;
    for (final session in sessionsThisWeek) {
      weeklyVolume += session.totalVolume;
    }

    final currentWeight = progressEntries.isNotEmpty
        ? progressEntries.first.weight
        : null;

    final activities = _buildRecentActivities(
      sessions: sessions,
      progressEntries: progressEntries,
      profile: profile,
      weeklySessions: sessionsThisWeek.length,
      weeklyVolume: weeklyVolume,
    );

    final recentPrs = _buildRecentPrs(sessions: sessions);

    return DashboardOverview(
      totalSessions: sessions.length,
      weeklySessions: sessionsThisWeek.length,
      weeklyVolume: weeklyVolume,
      currentWeight: currentWeight,
      lastSession: sessions.isNotEmpty ? sessions.first : null,
      latestProgressEntry: progressEntries.isNotEmpty
          ? progressEntries.first
          : null,
      profile: profile,
      recentActivities: activities,
      recentPrs: recentPrs,
    );
  }

  List<DashboardActivityItem> _buildRecentActivities({
    required List<WorkoutSession> sessions,
    required List<BodyProgressEntry> progressEntries,
    required BodyProfile profile,
    required int weeklySessions,
    required double weeklyVolume,
  }) {
    final List<DashboardActivityItem> items = [];

    if (sessions.isNotEmpty) {
      final lastSession = sessions.first;
      items.add(
        DashboardActivityItem(
          id: 'last_workout',
          title: 'Último entrenamiento guardado',
          subtitle:
              '${lastSession.routineName} • ${lastSession.totalExercises} ejercicios • ${lastSession.totalSets} series',
          sortOrder: 1,
        ),
      );
    }

    if (progressEntries.isNotEmpty) {
      final latest = progressEntries.first;
      String metricsText = 'Peso ${_formatNumber(latest.weight)} kg';

      if (latest.bodyFat != null) {
        metricsText += ' • ${_formatNumber(latest.bodyFat!)}% grasa';
      } else if (latest.waist != null) {
        metricsText += ' • cintura ${_formatNumber(latest.waist!)} cm';
      }

      items.add(
        DashboardActivityItem(
          id: 'latest_body_entry',
          title: 'Último registro corporal',
          subtitle: metricsText,
          sortOrder: 2,
        ),
      );
    }

    if (weeklySessions > 0) {
      items.add(
        DashboardActivityItem(
          id: 'weekly_summary',
          title: 'Resumen de esta semana',
          subtitle:
              '$weeklySessions entrenos • ${_formatNumber(weeklyVolume)} kg de volumen',
          sortOrder: 3,
        ),
      );
    } else {
      items.add(
        const DashboardActivityItem(
          id: 'weekly_empty',
          title: 'Semana todavía vacía',
          subtitle: 'Aún no has registrado entrenamientos esta semana.',
          sortOrder: 3,
        ),
      );
    }

    if (items.isEmpty) {
      items.add(
        const DashboardActivityItem(
          id: 'first_steps',
          title: 'Empieza a construir tu historial',
          subtitle:
              'Guarda tu primer entrenamiento y tu primer registro corporal.',
          sortOrder: 99,
        ),
      );
    }

    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return items.take(3).toList();
  }

  List<DashboardPersonalRecordItem> _buildRecentPrs({
    required List<WorkoutSession> sessions,
  }) {
    final chronologicalSessions = List<WorkoutSession>.from(sessions)
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));

    final Map<String, _ExerciseBestMark> bestByExercise = {};
    final List<DashboardPersonalRecordItem> prs = [];

    for (final session in chronologicalSessions) {
      for (final exercise in session.exercises) {
        for (final set in exercise.sets) {
          if (set.weight <= 0 || set.reps <= 0) continue;

          final best = bestByExercise[exercise.exerciseId];
          final isNewPr =
              best == null ||
              set.weight > best.weight ||
              (set.weight == best.weight && set.reps > best.reps);

          if (isNewPr) {
            bestByExercise[exercise.exerciseId] = _ExerciseBestMark(
              weight: set.weight,
              reps: set.reps,
            );

            prs.add(
              DashboardPersonalRecordItem(
                exerciseId: exercise.exerciseId,
                exerciseName: exercise.exerciseName,
                weight: set.weight,
                reps: set.reps,
                occurredAt: set.createdAt,
              ),
            );
          }
        }
      }
    }

    prs.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return prs.take(3).toList();
  }

  static String formatNumber(double value) => _formatNumber(value);

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }
}

class _ExerciseBestMark {
  final double weight;
  final int reps;

  const _ExerciseBestMark({required this.weight, required this.reps});
}
