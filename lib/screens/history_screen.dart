import 'package:flutter/material.dart';

import '../models/workout_session.dart';
import '../repositories/workout_repository.dart';
import '../services/app_repositories.dart';
import 'workout_detail_screen.dart';

enum _HistoryDateFilter { all, last7Days, last30Days, last90Days, thisYear }

class HistoryScreen extends StatefulWidget {
  final int refreshToken;

  const HistoryScreen({super.key, this.refreshToken = 0});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final WorkoutRepository _workoutRepository = AppRepositories.workouts;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<WorkoutSession> _allSessions = [];
  String? _selectedTag;
  _HistoryDateFilter _selectedDateFilter = _HistoryDateFilter.all;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onFiltersChanged);
    _reloadSessions();
  }

  @override
  void didUpdateWidget(covariant HistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _reloadSessions();
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onFiltersChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onFiltersChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _reloadSessions() async {
    setState(() {
      _isLoading = true;
    });

    final sessions = await _workoutRepository.getAllSessions();
    final sortedSessions = List<WorkoutSession>.from(sessions)
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

    if (!mounted) return;

    setState(() {
      _allSessions = sortedSessions;
      _isLoading = false;

      final availableTags = _availableTagsFromSessions(sortedSessions);
      if (_selectedTag != null && !availableTags.contains(_selectedTag)) {
        _selectedTag = null;
      }
    });
  }

  Future<void> _refresh() async {
    await _reloadSessions();
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

  String _displayTag(String tag) {
    switch (tag) {
      case 'pecho':
        return 'Pecho';
      case 'espalda':
        return 'Espalda';
      case 'hombro':
        return 'Hombro';
      case 'biceps':
        return 'Bíceps';
      case 'triceps':
        return 'Tríceps';
      case 'pierna':
        return 'Pierna';
      case 'abdomen':
        return 'Abdomen';
      default:
        if (tag.isEmpty) return tag;
        return tag[0].toUpperCase() + tag.substring(1);
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(date.year, date.month, date.day)).inDays;

    if (difference <= 0) return 'Hoy';
    if (difference == 1) return 'Ayer';
    if (difference < 7) return 'Hace $difference días';
    return _formatDate(date);
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    if (hours > 0) {
      if (minutes == 0) return '$hours h';
      return '$hours h $minutes min';
    }

    return '$minutes min';
  }

  String _formatVolume(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  String _dateFilterLabel(_HistoryDateFilter filter) {
    switch (filter) {
      case _HistoryDateFilter.all:
        return 'Todo';
      case _HistoryDateFilter.last7Days:
        return '7 días';
      case _HistoryDateFilter.last30Days:
        return '30 días';
      case _HistoryDateFilter.last90Days:
        return '90 días';
      case _HistoryDateFilter.thisYear:
        return 'Este año';
    }
  }

  List<String> _availableTagsFromSessions(List<WorkoutSession> sessions) {
    const order = [
      'pecho',
      'espalda',
      'hombro',
      'biceps',
      'triceps',
      'pierna',
      'abdomen',
    ];

    final tags = <String>{};
    for (final session in sessions) {
      tags.addAll(session.sessionTags.cast<String>());
    }

    final sorted = tags.toList()
      ..sort((a, b) {
        final indexA = order.indexOf(a);
        final indexB = order.indexOf(b);

        if (indexA == -1 && indexB == -1) return a.compareTo(b);
        if (indexA == -1) return 1;
        if (indexB == -1) return -1;
        return indexA.compareTo(indexB);
      });

    return sorted;
  }

  bool _matchesDateFilter(WorkoutSession session) {
    final now = DateTime.now();

    switch (_selectedDateFilter) {
      case _HistoryDateFilter.all:
        return true;
      case _HistoryDateFilter.last7Days:
        final cutoff = now.subtract(const Duration(days: 7));
        return !session.startedAt.isBefore(cutoff);
      case _HistoryDateFilter.last30Days:
        final cutoff = now.subtract(const Duration(days: 30));
        return !session.startedAt.isBefore(cutoff);
      case _HistoryDateFilter.last90Days:
        final cutoff = now.subtract(const Duration(days: 90));
        return !session.startedAt.isBefore(cutoff);
      case _HistoryDateFilter.thisYear:
        return session.startedAt.year == now.year;
    }
  }

  List<WorkoutSession> get _filteredSessions {
    final query = _normalizeText(_searchController.text.trim());

    return _allSessions.where((session) {
      final sessionTags = session.sessionTags.cast<String>();
      final matchesTag =
          _selectedTag == null || sessionTags.contains(_selectedTag);

      final normalizedName = _normalizeText(session.routineName);
      final normalizedTags = sessionTags.map(_normalizeText).toList();

      final exerciseNames = session.exercises
          .map((exercise) => _normalizeText(exercise.exerciseName))
          .toList();

      final matchesSearch =
          query.isEmpty ||
          normalizedName.contains(query) ||
          normalizedTags.any((tag) => tag.contains(query)) ||
          normalizedTags.any(
            (tag) => _normalizeText(_displayTag(tag)).contains(query),
          ) ||
          exerciseNames.any((name) => name.contains(query));

      final matchesDate = _matchesDateFilter(session);
      return matchesTag && matchesSearch && matchesDate;
    }).toList();
  }

  bool get _hasActiveFilters =>
      _searchController.text.trim().isNotEmpty ||
      _selectedTag != null ||
      _selectedDateFilter != _HistoryDateFilter.all;

  int get _sessionsThisWeek {
    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));

    return _allSessions.where((session) {
      final sessionDate = DateTime(
        session.startedAt.year,
        session.startedAt.month,
        session.startedAt.day,
      );
      return !sessionDate.isBefore(startOfWeek);
    }).length;
  }

  double get _totalHistoryVolume {
    return _allSessions.fold<double>(
      0,
      (sum, session) => sum + session.totalVolume,
    );
  }

  double get _filteredVolume {
    return _filteredSessions.fold<double>(
      0,
      (sum, session) => sum + session.totalVolume,
    );
  }

  void _clearFilters() {
    _searchController.clear();

    setState(() {
      _selectedTag = null;
      _selectedDateFilter = _HistoryDateFilter.all;
    });
  }

  Future<void> _clearAllHistory() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Borrar historial'),
              content: const Text(
                'Esto eliminará todos los entrenamientos guardados.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Borrar'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) return;

    await _workoutRepository.clearAllSessions();
    await _refresh();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Historial borrado'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openSessionDetail(WorkoutSession session) async {
    final navigator = Navigator.of(context);

    await navigator.push(
      MaterialPageRoute(builder: (_) => WorkoutDetailScreen(session: session)),
    );

    if (!mounted) return;
    await _refresh();
  }

  Widget _buildMetricPill(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _displayTag(tag),
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required IconData icon,
    String? hint,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
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
              fontSize: 12.5,
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

  Widget _buildOverviewSection() {
    final filteredSessions = _filteredSessions;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                label: 'Sesiones totales',
                value: '${_allSessions.length}',
                icon: Icons.history_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                label: 'Esta semana',
                value: '$_sessionsThisWeek',
                icon: Icons.calendar_today_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                label: 'Volumen histórico',
                value: '${_formatVolume(_totalHistoryVolume)} kg',
                icon: Icons.bar_chart_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                label: 'Resultados visibles',
                value: '${filteredSessions.length}',
                icon: Icons.filter_alt_rounded,
                hint: _hasActiveFilters
                    ? '${_formatVolume(_filteredVolume)} kg con los filtros actuales'
                    : 'Sin filtros activos',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActiveFiltersBar() {
    if (!_hasActiveFilters) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtros activos',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_searchController.text.trim().isNotEmpty)
                _buildMetricPill(
                  'Búsqueda: ${_searchController.text.trim()}',
                  Icons.search_rounded,
                ),
              if (_selectedTag != null)
                _buildMetricPill(
                  _displayTag(_selectedTag!),
                  Icons.sell_outlined,
                ),
              if (_selectedDateFilter != _HistoryDateFilter.all)
                _buildMetricPill(
                  _dateFilterLabel(_selectedDateFilter),
                  Icons.date_range_rounded,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Limpiar filtros'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    final availableTags = _availableTagsFromSessions(_allSessions);
    if (_allSessions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Buscar y filtrar',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, ejercicio o etiqueta',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.trim().isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Grupo muscular',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Todos'),
                selected: _selectedTag == null,
                onSelected: (_) {
                  setState(() {
                    _selectedTag = null;
                  });
                },
              ),
              ...availableTags.map(
                (tag) => ChoiceChip(
                  label: Text(_displayTag(tag)),
                  selected: _selectedTag == tag,
                  onSelected: (_) {
                    setState(() {
                      _selectedTag = tag;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Fecha',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _HistoryDateFilter.values.map((filter) {
              return ChoiceChip(
                label: Text(_dateFilterLabel(filter)),
                selected: _selectedDateFilter == filter,
                onSelected: (_) {
                  setState(() {
                    _selectedDateFilter = filter;
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _sessionExercisePreview(WorkoutSession session) {
    final names = session.exercises
        .map((exercise) => exercise.exerciseName)
        .where((name) => name.trim().isNotEmpty)
        .toList();

    if (names.isEmpty) {
      return 'Sin ejercicios detallados';
    }

    if (names.length <= 3) {
      return names.join(' • ');
    }

    final preview = names.take(3).join(' • ');
    final remaining = names.length - 3;
    return '$preview • +$remaining más';
  }

  Widget _buildSessionCard(WorkoutSession session) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openSessionDetail(session),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.history_rounded, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.routineName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatRelativeDate(session.startedAt)} • ${_formatTime(session.startedAt)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(session.startedAt),
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.white.withValues(alpha: 0.52),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 28,
                    color: Colors.white.withValues(alpha: 0.58),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                _sessionExercisePreview(session),
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                  color: Colors.white.withValues(alpha: 0.76),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildMetricPill(
                    '${session.totalExercises} ejercicios',
                    Icons.fitness_center_rounded,
                  ),
                  _buildMetricPill(
                    '${session.totalSets} series',
                    Icons.format_list_numbered_rounded,
                  ),
                  _buildMetricPill(
                    _formatDuration(session.durationSeconds),
                    Icons.timer_outlined,
                  ),
                  _buildMetricPill(
                    '${_formatVolume(session.totalVolume)} kg',
                    Icons.bar_chart_rounded,
                  ),
                ],
              ),
              if (session.sessionTags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: session.sessionTags
                      .cast<String>()
                      .map(_buildTagChip)
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyHistoryState() {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(Icons.history_rounded, size: 34),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Todavía no hay entrenamientos guardados',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cuando guardes tu primer entrenamiento aparecerá aquí con sus ejercicios, series, duración y volumen total.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      height: 1.45,
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilterState() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildOverviewSection(),
        const SizedBox(height: 16),
        _buildFilterSection(),
        const SizedBox(height: 16),
        _buildActiveFiltersBar(),
        if (_hasActiveFilters) const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.filter_alt_off_rounded, size: 32),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No hay entrenamientos con esos filtros',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Prueba otra etiqueta, otro rango de fecha o limpia la búsqueda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    height: 1.45,
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredSessions = _filteredSessions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [
          IconButton(
            onPressed: _reloadSessions,
            tooltip: 'Recargar',
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            onPressed: _allSessions.isEmpty ? null : _clearAllHistory,
            tooltip: 'Borrar historial',
            icon: const Icon(Icons.delete_sweep_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allSessions.isEmpty
          ? _buildEmptyHistoryState()
          : RefreshIndicator(
              onRefresh: _refresh,
              child: filteredSessions.isEmpty
                  ? _buildEmptyFilterState()
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildOverviewSection(),
                        const SizedBox(height: 16),
                        _buildFilterSection(),
                        const SizedBox(height: 16),
                        _buildActiveFiltersBar(),
                        if (_hasActiveFilters) const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _hasActiveFilters
                                ? 'Mostrando ${filteredSessions.length} de ${_allSessions.length} sesiones'
                                : 'Tus entrenamientos guardados',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        ...List.generate(filteredSessions.length, (index) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == filteredSessions.length - 1
                                  ? 0
                                  : 12,
                            ),
                            child: _buildSessionCard(filteredSessions[index]),
                          );
                        }),
                      ],
                    ),
            ),
    );
  }
}
