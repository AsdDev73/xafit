import 'package:flutter/material.dart';

import '../data/body_profile_storage.dart';
import '../data/body_progress_storage.dart';
import '../data/exercise_catalog.dart';
import '../data/workout_storage.dart';
import '../models/body_profile.dart';
import '../models/body_progress_entry.dart';
import '../models/workout_session.dart';
import 'workout_detail_screen.dart';
import 'workout_screen.dart';

class HomeScreen extends StatefulWidget {
  final int refreshToken;

  const HomeScreen({super.key, this.refreshToken = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  _HomeDashboardData _dashboard = const _HomeDashboardData.empty();

  @override
  void initState() {
    super.initState();
    _refreshDashboard();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.refreshToken != widget.refreshToken) {
      _refreshDashboard();
    }
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      _isLoading = true;
    });

    final sessions = await WorkoutStorage.loadSessions();
    final progressEntries = await BodyProgressStorage.loadEntries();
    final profile = await BodyProfileStorage.loadProfile();

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

    if (!mounted) return;

    setState(() {
      _dashboard = _HomeDashboardData(
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
      );
      _isLoading = false;
    });
  }

  List<_RecentActivityItem> _buildRecentActivities({
    required List<WorkoutSession> sessions,
    required List<BodyProgressEntry> progressEntries,
    required BodyProfile profile,
    required int weeklySessions,
    required double weeklyVolume,
  }) {
    final List<_RecentActivityItem> items = [];

    if (sessions.isNotEmpty) {
      final lastSession = sessions.first;
      items.add(
        _RecentActivityItem(
          icon: Icons.fitness_center_rounded,
          title: 'Último entrenamiento guardado',
          subtitle:
              '${lastSession.routineName} • ${lastSession.totalExercises} ejercicios • ${lastSession.totalSets} series',
          accentColor: const Color(0xFF4FC3F7),
        ),
      );
    }

    if (progressEntries.isNotEmpty) {
      final latest = progressEntries.first;

      String metricsText = 'Peso ${_formatStaticWeight(latest.weight)} kg';

      if (latest.bodyFat != null) {
        metricsText += ' • ${_formatStaticWeight(latest.bodyFat!)}% grasa';
      } else if (latest.waist != null) {
        metricsText += ' • cintura ${_formatStaticWeight(latest.waist!)} cm';
      }

      items.add(
        _RecentActivityItem(
          icon: Icons.monitor_weight_outlined,
          title: 'Último registro corporal',
          subtitle: metricsText,
          accentColor: const Color(0xFF4ADE80),
        ),
      );
    }

    if (weeklySessions > 0) {
      items.add(
        _RecentActivityItem(
          icon: Icons.insights_rounded,
          title: 'Resumen de esta semana',
          subtitle:
              '$weeklySessions entrenos • ${_formatStaticWeight(weeklyVolume)} kg de volumen',
          accentColor: const Color(0xFFFBBF24),
        ),
      );
    } else {
      items.add(
        const _RecentActivityItem(
          icon: Icons.calendar_today_rounded,
          title: 'Semana todavía vacía',
          subtitle: 'Aún no has registrado entrenamientos esta semana.',
          accentColor: Color(0xFFFBBF24),
        ),
      );
    }

    if (items.isEmpty) {
      items.add(
        _RecentActivityItem(
          icon: Icons.rocket_launch_rounded,
          title: 'Empieza a construir tu historial',
          subtitle:
              'Guarda tu primer entrenamiento y tu primer registro corporal.',
          accentColor: Colors.white70,
        ),
      );
    }

    return items.take(3).toList();
  }

  Future<void> _openAndRefresh(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

    await _refreshDashboard();
  }

  Future<void> _openLastSessionDetail() async {
    final session = _dashboard.lastSession;
    if (session == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WorkoutDetailScreen(session: session)),
    );

    await _refreshDashboard();
  }

  String _formatWeight(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  static String _formatStaticWeight(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDaysSince(DateTime date) {
    final diff = DateTime.now().difference(date).inDays;

    if (diff <= 0) return 'Hoy';
    if (diff == 1) return 'Hace 1 día';
    return 'Hace $diff días';
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: Colors.white70),
            const SizedBox(height: 12),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.72),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
    );
  }

  Widget _buildInfoPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildHeroCard() {
    final alias = _dashboard.profile.alias.trim().isEmpty
        ? 'Usuario'
        : _dashboard.profile.alias.trim();

    final subtitle = _dashboard.lastSession == null
        ? 'Empieza fuerte tu siguiente sesión y construye tu historial desde hoy.'
        : 'Último entreno: ${_formatDaysSince(_dashboard.lastSession!.startedAt)} • sigue sumando progreso.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E2A44), Color(0xFF203A43), Color(0xFF2C5364)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hola, $alias',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.88),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tu entrenamiento empieza aquí',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Colors.white.withOpacity(0.90),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoPill('${ExerciseCatalog.totalCount} ejercicios'),
              _buildInfoPill(
                '${_dashboard.weeklySessions} entrenos esta semana',
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _openAndRefresh(
                WorkoutScreen(
                  title: 'Entrenamiento libre',
                  availableExercises: ExerciseCatalog.allExercises,
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Empezar entrenamiento'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastSessionCard() {
    final session = _dashboard.lastSession;

    if (session == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Último entrenamiento',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              'Todavía no has guardado entrenamientos. Cuando registres el primero aparecerá aquí.',
              style: TextStyle(
                height: 1.45,
                color: Colors.white.withOpacity(0.74),
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: _openLastSessionDetail,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.history_rounded, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Último entrenamiento',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        session.routineName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 28),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '${_formatDate(session.startedAt)} • ${_formatTime(session.startedAt)}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.74),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoPill('${session.totalExercises} ejercicios'),
                _buildInfoPill('${session.totalSets} series'),
                _buildInfoPill('${_formatWeight(session.totalVolume)} kg'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard() {
    final activities = _dashboard.recentActivities;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actividad reciente',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Column(
            children: activities.map((item) {
              final isLast = item == activities.last;

              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: item.accentColor.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(item.icon, size: 20, color: item.accentColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.subtitle,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: Colors.white.withOpacity(0.72),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildObjectiveCard() {
    final profile = _dashboard.profile;
    final currentWeight = _dashboard.currentWeight;
    final targetWeight = profile.targetWeight;

    String statusText = profile.goal;
    String detailText =
        'Configura un objetivo corporal en Progreso para que XaFit tenga más contexto sobre tu evolución.';
    double? difference;
    bool? isOnTargetDirection;

    if (targetWeight != null && currentWeight != null) {
      difference = (targetWeight - currentWeight).abs();

      if (profile.goal.toLowerCase().contains('bajar')) {
        isOnTargetDirection = currentWeight <= targetWeight;
      } else if (profile.goal.toLowerCase().contains('subir')) {
        isOnTargetDirection = currentWeight >= targetWeight;
      }

      detailText =
          'Actual ${_formatWeight(currentWeight)} kg • objetivo ${_formatWeight(targetWeight)} kg';
    } else if (targetWeight != null) {
      detailText =
          'Objetivo configurado en ${_formatWeight(targetWeight)} kg. Registra tu peso actual para compararlo.';
    }

    final Color statusColor = isOnTargetDirection == null
        ? const Color(0xFF4FC3F7)
        : isOnTargetDirection
        ? const Color(0xFF4ADE80)
        : const Color(0xFFFBBF24);

    final String statusLabel = isOnTargetDirection == null
        ? 'Objetivo activo'
        : isOnTargetDirection
        ? 'Objetivo alcanzado'
        : 'En progreso';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Objetivo actual',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            detailText,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: Colors.white.withOpacity(0.74),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildObjectiveMiniBox(
                label: 'Peso actual',
                value: currentWeight != null
                    ? '${_formatWeight(currentWeight)} kg'
                    : '--',
              ),
              const SizedBox(width: 10),
              _buildObjectiveMiniBox(
                label: 'Peso objetivo',
                value: targetWeight != null
                    ? '${_formatWeight(targetWeight)} kg'
                    : '--',
              ),
              const SizedBox(width: 10),
              _buildObjectiveMiniBox(
                label: 'Diferencia',
                value: difference != null
                    ? '${_formatWeight(difference)} kg'
                    : '--',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildObjectiveMiniBox({
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.white.withOpacity(0.68),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentWeight = _dashboard.currentWeight != null
        ? '${_formatWeight(_dashboard.currentWeight!)} kg'
        : '--';

    final weeklyVolume = '${_formatWeight(_dashboard.weeklyVolume)} kg';

    return Scaffold(
      appBar: AppBar(
        title: const Text('XaFit'),
        actions: [
          IconButton(
            onPressed: _refreshDashboard,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshDashboard,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _buildHeroCard(),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _buildMetricCard(
                        label: 'Entrenos totales',
                        value: '${_dashboard.totalSessions}',
                        icon: Icons.fitness_center_rounded,
                      ),
                      const SizedBox(width: 10),
                      _buildMetricCard(
                        label: 'Peso actual',
                        value: currentWeight,
                        icon: Icons.monitor_weight_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildMetricCard(
                        label: 'Entrenos semana',
                        value: '${_dashboard.weeklySessions}',
                        icon: Icons.calendar_today_rounded,
                      ),
                      const SizedBox(width: 10),
                      _buildMetricCard(
                        label: 'Volumen semana',
                        value: weeklyVolume,
                        icon: Icons.bar_chart_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _buildSectionTitle('Último entrenamiento'),
                  const SizedBox(height: 12),
                  _buildLastSessionCard(),
                  const SizedBox(height: 22),
                  _buildSectionTitle('Actividad reciente'),
                  const SizedBox(height: 12),
                  _buildActivityCard(),
                  const SizedBox(height: 22),
                  _buildSectionTitle('Objetivo actual'),
                  const SizedBox(height: 12),
                  _buildObjectiveCard(),
                ],
              ),
            ),
    );
  }
}

class _HomeDashboardData {
  final int totalSessions;
  final int weeklySessions;
  final double weeklyVolume;
  final double? currentWeight;
  final WorkoutSession? lastSession;
  final BodyProgressEntry? latestProgressEntry;
  final BodyProfile profile;
  final List<_RecentActivityItem> recentActivities;

  const _HomeDashboardData({
    required this.totalSessions,
    required this.weeklySessions,
    required this.weeklyVolume,
    required this.currentWeight,
    required this.lastSession,
    required this.latestProgressEntry,
    required this.profile,
    required this.recentActivities,
  });

  const _HomeDashboardData.empty()
    : totalSessions = 0,
      weeklySessions = 0,
      weeklyVolume = 0,
      currentWeight = null,
      lastSession = null,
      latestProgressEntry = null,
      profile = BodyProfile.empty,
      recentActivities = const [];
}

class _RecentActivityItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;

  const _RecentActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
  });
}
