import 'package:flutter/material.dart';

import '../data/body_progress_storage.dart';
import '../data/exercise_catalog.dart';
import '../data/routine_seed.dart';
import '../data/workout_storage.dart';
import '../models/workout_session.dart';
import 'history_screen.dart';
import 'progress_screen.dart';
import 'routines_screen.dart';
import 'workout_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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

  Future<void> _refreshDashboard() async {
    setState(() {
      _isLoading = true;
    });

    final sessions = await WorkoutStorage.loadSessions();
    final progressEntries = await BodyProgressStorage.loadEntries();

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

    if (!mounted) return;

    setState(() {
      _dashboard = _HomeDashboardData(
        totalSessions: sessions.length,
        weeklySessions: sessionsThisWeek.length,
        weeklyVolume: weeklyVolume,
        currentWeight: currentWeight,
        lastSession: sessions.isNotEmpty ? sessions.first : null,
      );
      _isLoading = false;
    });
  }

  String _formatWeight(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  String _formatVolume(double value) {
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

  Future<void> _openAndRefresh(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

    await _refreshDashboard();
  }

  Widget _buildMiniStat({required String title, required String value}) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.72),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.70),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLastSessionCard() {
    final session = _dashboard.lastSession;

    if (session == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Último entrenamiento',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(
                'Todavía no has guardado entrenamientos.',
                style: TextStyle(color: Colors.white.withOpacity(0.75)),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Último entrenamiento',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              session.routineName,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${_formatDate(session.startedAt)} • ${_formatTime(session.startedAt)}',
              style: TextStyle(color: Colors.white.withOpacity(0.75)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildInfoPill('${session.totalExercises} ejercicios'),
                _buildInfoPill('${session.totalSets} series'),
                _buildInfoPill('${_formatVolume(session.totalVolume)} kg'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupCount = defaultRoutines.length;
    final exerciseCount = ExerciseCatalog.totalCount;
    final currentWeight = _dashboard.currentWeight != null
        ? '${_formatWeight(_dashboard.currentWeight!)} kg'
        : '--';
    final weeklyVolume = '${_formatVolume(_dashboard.weeklyVolume)} kg';

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
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF203A43), Color(0xFF2C5364)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tu entrenamiento empieza aquí',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Controla tu semana, registra tu progreso y entrena con todo en una sola app.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.90),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => _openAndRefresh(
                              WorkoutScreen(
                                title: 'Entrenamiento libre',
                                availableExercises:
                                    ExerciseCatalog.allExercises,
                              ),
                            ),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Empezar entrenamiento'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildMiniStat(
                        title: 'Entrenos totales',
                        value: '${_dashboard.totalSessions}',
                      ),
                      const SizedBox(width: 12),
                      _buildMiniStat(
                        title: 'Peso actual',
                        value: currentWeight,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildMiniStat(
                        title: 'Entrenos semana',
                        value: '${_dashboard.weeklySessions}',
                      ),
                      const SizedBox(width: 12),
                      _buildMiniStat(
                        title: 'Volumen semana',
                        value: weeklyVolume,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildMiniStat(title: 'Grupos', value: '$groupCount'),
                      const SizedBox(width: 12),
                      _buildMiniStat(
                        title: 'Ejercicios',
                        value: '$exerciseCount',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Resumen',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _buildLastSessionCard(),
                  const SizedBox(height: 18),
                  const Text(
                    'Accesos rápidos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _buildQuickActionCard(
                    icon: Icons.show_chart_rounded,
                    title: 'Progreso',
                    subtitle: 'Peso, medidas y gráfica corporal',
                    onTap: () => _openAndRefresh(const ProgressScreen()),
                  ),
                  _buildQuickActionCard(
                    icon: Icons.menu_book_rounded,
                    title: 'Biblioteca',
                    subtitle: 'Explora ejercicios por grupo muscular',
                    onTap: () => _openAndRefresh(const RoutinesScreen()),
                  ),
                  _buildQuickActionCard(
                    icon: Icons.history_rounded,
                    title: 'Historial',
                    subtitle: 'Consulta tus entrenamientos anteriores',
                    onTap: () => _openAndRefresh(const HistoryScreen()),
                  ),
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

  const _HomeDashboardData({
    required this.totalSessions,
    required this.weeklySessions,
    required this.weeklyVolume,
    required this.currentWeight,
    required this.lastSession,
  });

  const _HomeDashboardData.empty()
    : totalSessions = 0,
      weeklySessions = 0,
      weeklyVolume = 0,
      currentWeight = null,
      lastSession = null;
}
