import 'package:flutter/material.dart';

import '../data/workout_storage.dart';
import '../models/workout_session.dart';
import 'workout_detail_screen.dart';

enum _HistoryDateFilter { all, last7Days, last30Days, last90Days, thisYear }

class HistoryScreen extends StatefulWidget {
  final int refreshToken;

  const HistoryScreen({super.key, this.refreshToken = 0});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
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
    setState(() {});
  }

  Future<void> _reloadSessions() async {
    setState(() {
      _isLoading = true;
    });

    final sessions = await WorkoutStorage.loadSessions();

    if (!mounted) return;

    setState(() {
      _allSessions = sessions;
      _isLoading = false;

      if (_selectedTag != null &&
          !_availableTagsFromSessions(sessions).contains(_selectedTag)) {
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

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
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
      tags.addAll(session.sessionTags);
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
        return session.startedAt.isAfter(now.subtract(const Duration(days: 7)));
      case _HistoryDateFilter.last30Days:
        return session.startedAt.isAfter(
          now.subtract(const Duration(days: 30)),
        );
      case _HistoryDateFilter.last90Days:
        return session.startedAt.isAfter(
          now.subtract(const Duration(days: 90)),
        );
      case _HistoryDateFilter.thisYear:
        return session.startedAt.year == now.year;
    }
  }

  List<WorkoutSession> get _filteredSessions {
    final query = _normalizeText(_searchController.text.trim());

    return _allSessions.where((session) {
      final matchesTag =
          _selectedTag == null || session.sessionTags.contains(_selectedTag);

      final normalizedName = _normalizeText(session.routineName);
      final normalizedTags = session.sessionTags.map(_normalizeText).toList();

      final matchesSearch =
          query.isEmpty ||
          normalizedName.contains(query) ||
          normalizedTags.any((tag) => tag.contains(query)) ||
          normalizedTags.any(
            (tag) => _normalizeText(_displayTag(tag)).contains(query),
          );

      final matchesDate = _matchesDateFilter(session);

      return matchesTag && matchesSearch && matchesDate;
    }).toList();
  }

  Future<void> _clearAllHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Borrar historial'),
          content: const Text(
            'Esto eliminará todos los entrenamientos guardados.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Borrar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await WorkoutStorage.clearAllSessions();
    await _refresh();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Historial borrado'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildMetricPill(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _displayTag(tag),
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildFilterSection() {
    final availableTags = _availableTagsFromSessions(_allSessions);

    if (_allSessions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o etiqueta',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
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
            'Filtrar por grupo principal',
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
            'Filtrar por fecha',
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

  Widget _buildSessionCard(WorkoutSession session) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WorkoutDetailScreen(session: session),
            ),
          );

          await _refresh();
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
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
                          '${_formatDate(session.startedAt)} • ${_formatTime(session.startedAt)}',
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
                  children: session.sessionTags.map(_buildTagChip).toList(),
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
                      color: Colors.white.withOpacity(0.06),
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
                    'Cuando guardes tu primer entrenamiento aparecerá aquí con sus ejercicios, series y volumen total.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      height: 1.45,
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
  }

  Widget _buildEmptyFilterState() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildFilterSection(),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
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
                    color: Colors.white.withOpacity(0.72),
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
            onPressed: _clearAllHistory,
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
                        _buildFilterSection(),
                        const SizedBox(height: 16),
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
