import 'package:flutter/material.dart';

import '../data/exercise_catalog.dart';
import '../services/app_repositories.dart';
import '../services/dashboard_service.dart';
import '../services/workout_draft_service.dart'
    show WorkoutDraft, WorkoutDraftService;
import 'workout_detail_screen.dart';
import 'workout_screen.dart' show WorkoutScreen;

class HomeScreen extends StatefulWidget {
  final int refreshToken;

  const HomeScreen({super.key, this.refreshToken = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DashboardService _dashboardService = AppRepositories.dashboardService;
  final WorkoutDraftService _workoutDraftService = const WorkoutDraftService();

  bool _isLoading = true;
  DashboardOverview _dashboard = const DashboardOverview.empty();
  WorkoutDraft? _activeDraft;

  @override
  void initState() {
    super.initState();
    _refreshHome();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _refreshHome();
    }
  }

  Future<void> _refreshHome() async {
    setState(() {
      _isLoading = true;
    });

    final overview = await _dashboardService.loadOverview();
    final draft = await _workoutDraftService.loadDraft();

    if (!mounted) return;

    setState(() {
      _dashboard = overview;
      _activeDraft = draft;
      _isLoading = false;
    });
  }

  Future<void> _openAndRefresh(Widget screen) async {
    final navigator = Navigator.of(context);

    await navigator.push(MaterialPageRoute(builder: (_) => screen));

    if (!mounted) return;
    await _refreshHome();
  }

  Future<void> _openLastSessionDetail() async {
    final session = _dashboard.lastSession;
    if (session == null) return;

    final navigator = Navigator.of(context);

    await navigator.push(
      MaterialPageRoute(builder: (_) => WorkoutDetailScreen(session: session)),
    );

    if (!mounted) return;
    await _refreshHome();
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  String _formatWeight(double value) => '${_formatNumber(value)} kg';

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  String _formatLongDate(DateTime date) {
    const months = <String>[
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];

    return '${date.day} ${months[date.month - 1]}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _personalRecordTypeLabel(DashboardPersonalRecordType type) {
    switch (type) {
      case DashboardPersonalRecordType.weight:
        return 'PR de peso';
      case DashboardPersonalRecordType.reps:
        return 'PR de reps';
      case DashboardPersonalRecordType.volume:
        return 'PR de volumen';
    }
  }

  String _personalRecordValue(DashboardPersonalRecordItem pr) {
    switch (pr.type) {
      case DashboardPersonalRecordType.weight:
        return '${_formatWeight(pr.weight)} × ${pr.reps} reps';
      case DashboardPersonalRecordType.reps:
        return '${pr.reps} reps con ${_formatWeight(pr.weight)}';
      case DashboardPersonalRecordType.volume:
        return '${_formatWeight(pr.weight)} × ${pr.reps} • ${_formatWeight(pr.volume)}';
    }
  }

  String _formatDaysSince(DateTime date) {
    final diff = DateTime.now().difference(date).inDays;

    if (diff <= 0) return 'Hoy';
    if (diff == 1) return 'Hace 1 día';
    return 'Hace $diff días';
  }

  String _formatDraftAge(DateTime startedAt) {
    final diff = DateTime.now().difference(startedAt);

    if (diff.inMinutes < 1) return 'Hace un momento';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return 'Hace ${diff.inDays} días';
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    if (minutes < 60) {
      if (seconds == 0) return '$minutes min';
      return '$minutes min';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) return '$hours h';
    return '$hours h $remainingMinutes min';
  }

  String? _notePreview(String? notes) {
    if (notes == null) return null;

    final normalized = notes.replaceAll('\n', ' ').trim();
    if (normalized.isEmpty) return null;

    if (normalized.length <= 90) return normalized;
    return '${normalized.substring(0, 90).trim()}...';
  }

  int _draftSetCount(WorkoutDraft draft) {
    return draft.exercises.fold<int>(
      0,
      (total, exercise) => total + exercise.sets.length,
    );
  }

  Future<void> _continueDraft() async {
    final draft = _activeDraft;
    if (draft == null) return;

    final navigator = Navigator.of(context);

    await navigator.push(
      MaterialPageRoute(
        builder: (_) => WorkoutScreen(
          title: draft.title,
          availableExercises: ExerciseCatalog.allExercises,
        ),
      ),
    );

    if (!mounted) return;
    await _refreshHome();
  }

  Future<void> _discardDraft() async {
    final draft = _activeDraft;
    if (draft == null) return;

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Descartar entrenamiento en curso'),
              content: const Text(
                'Se eliminará el borrador actual y no podrás recuperarlo después.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Descartar'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) return;

    await _workoutDraftService.clearDraft();

    if (!mounted) return;

    setState(() {
      _activeDraft = null;
    });

    _showMessage('Borrador descartado');
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    String? hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 8),
            Text(
              hint,
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.white.withValues(alpha: 0.56),
              ),
            ),
          ],
        ],
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
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _heroSubtitle() {
    final lastSession = _dashboard.lastSession;

    if (lastSession == null) {
      return 'Empieza fuerte tu siguiente sesión y construye tu historial desde hoy.';
    }

    if (_dashboard.weeklySessions > 0) {
      return 'Llevas ${_dashboard.weeklySessions} entrenos esta semana. Sigue sumando progreso.';
    }

    return 'Último entreno: ${_formatDaysSince(lastSession.startedAt)} • vuelve a activar la semana.';
  }

  Widget _buildHeroCard() {
    final alias = _dashboard.profile.alias.trim().isEmpty
        ? 'Usuario'
        : _dashboard.profile.alias.trim();

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
            color: Colors.black.withValues(alpha: 0.18),
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
              color: Colors.white.withValues(alpha: 0.88),
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
            _heroSubtitle(),
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Colors.white.withValues(alpha: 0.90),
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
              _buildInfoPill('${_dashboard.totalSessions} sesiones totales'),
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

  Widget _buildDraftBanner(WorkoutDraft draft) {
    final exerciseCount = draft.exercises.length;
    final setCount = _draftSetCount(draft);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.fitness_center_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Entreno en curso',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.96),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${draft.title} • ${_formatDraftAge(draft.startedAt)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.68),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoPill('$exerciseCount ejercicios'),
              _buildInfoPill('$setCount series'),
              if (draft.currentRestSeconds > 0)
                _buildInfoPill('Descanso ${draft.currentRestSeconds}s'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _continueDraft,
                  child: const Text('Continuar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: _discardDraft,
                  child: const Text('Descartar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopMetrics() {
    final currentWeight = _dashboard.currentWeight;
    final weeklyVolumeText = _dashboard.weeklyVolume > 0
        ? '${_formatNumber(_dashboard.weeklyVolume)} kg'
        : '—';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                label: 'Sesiones totales',
                value: '${_dashboard.totalSessions}',
                icon: Icons.history_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                label: 'Esta semana',
                value: '${_dashboard.weeklySessions}',
                icon: Icons.calendar_today_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                label: 'Volumen semanal',
                value: weeklyVolumeText,
                icon: Icons.local_fire_department_outlined,
                hint: _dashboard.weeklySessions > 0
                    ? 'Trabajo acumulado en tus sesiones de esta semana'
                    : 'Aún no hay volumen registrado esta semana',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                label: 'Peso actual',
                value: currentWeight != null
                    ? _formatWeight(currentWeight)
                    : '—',
                icon: Icons.monitor_weight_outlined,
                hint: currentWeight != null
                    ? 'Tomado de tu último registro corporal'
                    : 'Añade un registro en Progreso para verlo aquí',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickInsightStrip() {
    final latestEntry = _dashboard.latestProgressEntry;
    final lastSession = _dashboard.lastSession;

    String leftTitle = 'Sin registro corporal';
    String leftValue = 'Añade uno en Progreso';
    if (latestEntry != null) {
      leftTitle = 'Último peso';
      leftValue =
          '${_formatWeight(latestEntry.weight)} • ${_formatDate(latestEntry.date)}';
    }

    String rightTitle = 'Sin último entreno';
    String rightValue = 'Crea una sesión';
    if (lastSession != null) {
      rightTitle = 'Última sesión';
      rightValue =
          '${lastSession.totalSets} series • ${_formatDaysSince(lastSession.startedAt)}';
    }

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            label: leftTitle,
            value: leftValue,
            icon: Icons.show_chart_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            label: rightTitle,
            value: rightValue,
            icon: Icons.bolt_rounded,
          ),
        ),
      ],
    );
  }

  String _weeklyHeadline() {
    final weeklySessions = _dashboard.weeklySessions;

    if (weeklySessions >= 4) return 'Semana muy sólida';
    if (weeklySessions >= 2) return 'Semana en buen ritmo';
    if (weeklySessions == 1) return 'Ya has arrancado la semana';
    return 'Tu semana aún está vacía';
  }

  String _weeklySubtitle() {
    final weeklySessions = _dashboard.weeklySessions;
    final volume = _dashboard.weeklyVolume;

    if (weeklySessions <= 0) {
      return 'Un entrenamiento hoy ya te pone en marcha.';
    }

    if (volume > 0) {
      return '$weeklySessions entrenos y ${_formatNumber(volume)} kg de volumen acumulado.';
    }

    return '$weeklySessions entrenos registrados esta semana.';
  }

  Color _weeklyAccent() {
    final weeklySessions = _dashboard.weeklySessions;

    if (weeklySessions >= 4) return const Color(0xFF4FC3F7);
    if (weeklySessions >= 2) return const Color(0xFF81C784);
    if (weeklySessions == 1) return const Color(0xFFFFD54F);
    return const Color(0xFFE57373);
  }

  Widget _buildWeeklyFocusCard() {
    final accent = _weeklyAccent();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.insights_outlined, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _weeklyHeadline(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _weeklySubtitle(),
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: Colors.white.withValues(alpha: 0.74),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildInfoPill('${_dashboard.weeklySessions} entrenos'),
                    _buildInfoPill(
                      _dashboard.weeklyVolume > 0
                          ? '${_formatNumber(_dashboard.weeklyVolume)} kg'
                          : '0 kg',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _goalIcon(String goal) {
    final normalized = goal.trim().toLowerCase();

    if (normalized.contains('volumen')) return Icons.trending_up_rounded;
    if (normalized.contains('defin')) return Icons.track_changes_rounded;
    if (normalized.contains('perd')) return Icons.monitor_weight_outlined;
    if (normalized.contains('gan')) return Icons.fitness_center_rounded;
    return Icons.flag_outlined;
  }

  String _goalSubtitle() {
    final profile = _dashboard.profile;
    final currentWeight = _dashboard.currentWeight;
    final targetWeight = profile.targetWeight;

    if (targetWeight == null && currentWeight == null) {
      return 'Configura tu objetivo y añade registros corporales para seguir mejor tu progreso.';
    }

    if (targetWeight != null && currentWeight == null) {
      return 'Objetivo marcado en ${_formatWeight(targetWeight)}. Falta un registro actual para medir distancia.';
    }

    if (targetWeight == null && currentWeight != null) {
      return 'Tu peso actual registrado es ${_formatWeight(currentWeight)}. Añade un peso objetivo para seguir la diferencia.';
    }

    final diff = (targetWeight! - currentWeight!).abs();
    final toward = targetWeight > currentWeight ? 'por ganar' : 'por bajar';

    if (diff == 0) {
      return 'Ya estás exactamente en tu peso objetivo.';
    }

    return 'Te quedan ${_formatNumber(diff)} kg $toward para llegar a ${_formatWeight(targetWeight)}.';
  }

  Widget _buildGoalCard() {
    final profile = _dashboard.profile;
    final currentWeight = _dashboard.currentWeight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_goalIcon(profile.goal)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Objetivo actual',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoPill(
                profile.goal.isEmpty ? 'Sin objetivo' : profile.goal,
              ),
              if (profile.targetWeight != null)
                _buildInfoPill('Meta ${_formatWeight(profile.targetWeight!)}'),
              if (currentWeight != null)
                _buildInfoPill('Actual ${_formatWeight(currentWeight)}'),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _goalSubtitle(),
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: Colors.white.withValues(alpha: 0.74),
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
          color: const Color(0xFF1A1F2B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Último entrenamiento',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              'Todavía no has guardado sesiones. Cuando registres tu primer entrenamiento aparecerá aquí con su resumen.',
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: Colors.white.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _openAndRefresh(
                WorkoutScreen(
                  title: 'Entrenamiento libre',
                  availableExercises: ExerciseCatalog.allExercises,
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Crear primer entrenamiento'),
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
          color: const Color(0xFF1A1F2B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Último entrenamiento',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              session.routineName,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              '${_formatLongDate(session.startedAt)} • ${_formatTime(session.startedAt)} • ${_formatDaysSince(session.startedAt)}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.70),
              ),
            ),
            if (_notePreview(session.notes) != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.sticky_note_2_outlined,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.68),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _notePreview(session.notes)!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Colors.white.withValues(alpha: 0.74),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoPill('${session.totalExercises} ejercicios'),
                _buildInfoPill('${session.totalSets} series'),
                _buildInfoPill(_formatWeight(session.totalVolume)),
                _buildInfoPill(_formatDuration(session.durationSeconds)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPrsCard() {
    final prs = _dashboard.recentPrs;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mejores marcas recientes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            prs.isEmpty
                ? 'Cuando superes tus marcas en un ejercicio aparecerán aquí.'
                : 'Tus últimos PRs automáticos en peso, reps o volumen (sin contar calentamiento).',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          if (prs.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...List.generate(prs.length, (index) {
              final pr = prs[index];
              final isLast = index == prs.length - 1;

              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
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
                              pr.exerciseName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
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
                                    _personalRecordTypeLabel(pr.type),
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _personalRecordValue(pr),
                              style: TextStyle(
                                fontSize: 13.5,
                                color: Colors.white.withValues(alpha: 0.78),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${_formatLongDate(pr.occurredAt)} • ${_formatTime(pr.occurredAt)}',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.white.withValues(alpha: 0.58),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    final activities = _dashboard.recentActivities;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actividad reciente',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          if (activities.isEmpty)
            Text(
              'Todavía no hay actividad reciente para mostrar.',
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.white.withValues(alpha: 0.72),
              ),
            )
          else ...[
            for (int i = 0; i < activities.length; i++) ...[
              _ActivityTile(item: activities[i]),
              if (i != activities.length - 1) ...[
                const SizedBox(height: 10),
                Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = RefreshIndicator(
      onRefresh: _refreshHome,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _buildHeroCard(),
          if (_activeDraft != null) ...[
            const SizedBox(height: 16),
            _buildDraftBanner(_activeDraft!),
          ],
          const SizedBox(height: 20),
          _buildSectionTitle('Resumen'),
          const SizedBox(height: 12),
          _buildTopMetrics(),
          const SizedBox(height: 12),
          _buildQuickInsightStrip(),
          const SizedBox(height: 20),
          _buildSectionTitle('Enfoque de la semana'),
          const SizedBox(height: 12),
          _buildWeeklyFocusCard(),
          const SizedBox(height: 20),
          _buildSectionTitle('Mejores marcas'),
          const SizedBox(height: 12),
          _buildRecentPrsCard(),
          const SizedBox(height: 20),
          _buildSectionTitle('Objetivo actual'),
          const SizedBox(height: 12),
          _buildGoalCard(),
          const SizedBox(height: 20),
          _buildSectionTitle('Último entrenamiento'),
          const SizedBox(height: 12),
          _buildLastSessionCard(),
          const SizedBox(height: 20),
          _buildSectionTitle('Actividad reciente'),
          const SizedBox(height: 12),
          _buildRecentActivitySection(),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Inicio')),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _isLoading
            ? const Center(
                key: ValueKey('loading'),
                child: CircularProgressIndicator(),
              )
            : KeyedSubtree(key: const ValueKey('content'), child: body),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final DashboardActivityItem item;

  const _ActivityTile({required this.item});

  IconData _iconForId() {
    switch (item.id) {
      case 'last_workout':
        return Icons.fitness_center_rounded;
      case 'latest_body_entry':
        return Icons.monitor_weight_outlined;
      case 'weekly_summary':
        return Icons.insights_outlined;
      case 'weekly_empty':
        return Icons.event_busy_outlined;
      case 'first_steps':
        return Icons.flag_outlined;
      default:
        return Icons.bolt_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(_iconForId(), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.subtitle,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
