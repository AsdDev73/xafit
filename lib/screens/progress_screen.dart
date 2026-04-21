import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/body_profile.dart';
import '../models/body_progress_entry.dart';
import '../services/app_repositories.dart';
import '../services/notification_service.dart';
import '../services/progress_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

/// Estado y lógica de la pantalla de Progreso.
///
/// Aquí se centraliza la carga del perfil, el historial corporal,
/// la selección de la métrica visible en la gráfica y la configuración
/// del recordatorio semanal para el peso.
class _ProgressScreenState extends State<ProgressScreen> {
  // Servicio que encapsula perfil + registros de progreso.
  final ProgressService _progressService = ProgressService(
    bodyProfileRepository: AppRepositories.bodyProfile,
    bodyProgressRepository: AppRepositories.bodyProgress,
  );

  // Perfil actual del usuario.
  BodyProfile _profile = BodyProfile.empty;

  // Historial completo de registros corporales.
  List<BodyProgressEntry> _entries = [];

  // Estado general de carga de la pantalla.
  bool _isLoading = true;

  // Estado de carga específico del recordatorio semanal.
  bool _isReminderLoading = false;

  // Métrica actualmente seleccionada para la gráfica y el historial.
  _ProgressMetric _selectedMetric = _ProgressMetric.weight;

  // Configuración persistida del recordatorio semanal.
  WeeklyReminderSettings _weeklyReminderSettings =
      const WeeklyReminderSettings.defaultValue();

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  /// Recarga toda la información visible de la pantalla.
  ///
  /// Trae perfil, entradas de progreso y la configuración actual del
  /// recordatorio semanal. Después ordena el historial por fecha ascendente
  /// para que la gráfica siempre tenga el eje temporal correcto.
  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
    });

    final overview = await _progressService.loadOverview();
    final entries = List<BodyProgressEntry>.from(overview.entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    if (!mounted) return;

    setState(() {
      _profile = overview.profile;
      _entries = entries;
      _weeklyReminderSettings = overview.reminderSettings;
      _isLoading = false;
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

  Future<void> _exportBackup() async {
    try {
      final file = await AppRepositories.backupService.exportBackupToTempFile();

      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Backup de XaFit',
        subject: 'Backup de XaFit',
      );

      if (!mounted) return;

      if (result.status == ShareResultStatus.success) {
        _showFloatingSnackBar('Backup exportado');
      } else {
        _showFloatingSnackBar('Backup generado');
      }
    } catch (_) {
      if (!mounted) return;
      _showFloatingSnackBar('Error al exportar el backup');
    }
  }

  Future<void> _importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null) {
        if (!mounted) return;
        _showFloatingSnackBar('Importación cancelada');
        return;
      }

      final path = result.files.single.path;
      if (path == null || path.isEmpty) {
        if (!mounted) return;
        _showFloatingSnackBar('No se pudo leer el archivo seleccionado');
        return;
      }

      final importResult =
          await AppRepositories.backupService.importBackupFromFile(File(path));

      await _refresh();

      if (!mounted) return;

      _showFloatingSnackBar(
        'Importado: '
        '${importResult.importedSessions} sesiones, '
        '${importResult.importedProgressEntries} registros, '
        '${importResult.importedCustomExercises} ejercicios'
        '${importResult.profileImported ? ', perfil incluido' : ''}',
      );
    } on FormatException catch (e) {
      if (!mounted) return;
      _showFloatingSnackBar(e.message);
    } catch (_) {
      if (!mounted) return;
      _showFloatingSnackBar('Error al importar el backup');
    }
  }

  Future<void> _confirmImportBackup() async {
    final shouldImport = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Importar backup'),
          content: const Text(
            'La importación añadirá sesiones, registros y ejercicios desde el archivo seleccionado. '
            'Haz una exportación antes si quieres una copia de seguridad extra.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );

    if (shouldImport == true) {
      await _importBackup();
    }
  }

  /// Devuelve la hora del recordatorio en formato HH:mm.
  String _formatReminderTime(WeeklyReminderSettings settings) {
    final hour = settings.hour.toString().padLeft(2, '0');
    final minute = settings.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Activa o desactiva el recordatorio semanal.
  ///
  /// Si se activa, intenta programar una notificación semanal real en
  /// móvil/escritorio y, en web, al menos deja persistida la preferencia.
  Future<void> _toggleWeeklyReminder(bool enabled) async {
    setState(() {
      _isReminderLoading = true;
    });

    try {
      if (enabled) {
        await NotificationService.scheduleWeeklyWeightReminder(
          hour: _weeklyReminderSettings.hour,
          minute: _weeklyReminderSettings.minute,
        );
      } else {
        await NotificationService.cancelWeeklyWeightReminder();
      }

      if (!mounted) return;

      setState(() {
        _weeklyReminderSettings = _weeklyReminderSettings.copyWith(
          enabled: enabled,
        );
      });

      _showFloatingSnackBar(
        enabled
            ? (kIsWeb
                ? 'Configuración del recordatorio guardada'
                : 'Recordatorio semanal activado')
            : 'Recordatorio semanal desactivado',
      );
    } catch (e) {
      if (!mounted) return;
      _showFloatingSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isReminderLoading = false;
        });
      }
    }
  }

  /// Permite elegir una nueva hora para el recordatorio semanal.
  ///
  /// Si el recordatorio ya estaba activo, al cambiar la hora se reprograma
  /// automáticamente para no obligar al usuario a apagarlo y volver a encenderlo.
  Future<void> _pickWeeklyReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _weeklyReminderSettings.hour,
        minute: _weeklyReminderSettings.minute,
      ),
    );

    if (picked == null) return;

    setState(() {
      _isReminderLoading = true;
    });

    try {
      await NotificationService.saveWeeklyReminderTime(
        hour: picked.hour,
        minute: picked.minute,
      );

      if (_weeklyReminderSettings.enabled) {
        await NotificationService.scheduleWeeklyWeightReminder(
          hour: picked.hour,
          minute: picked.minute,
          requestPermission: false,
        );
      }

      if (!mounted) return;

      setState(() {
        _weeklyReminderSettings = _weeklyReminderSettings.copyWith(
          hour: picked.hour,
          minute: picked.minute,
        );
      });

      _showFloatingSnackBar(
        _weeklyReminderSettings.enabled
            ? 'Hora del recordatorio actualizada'
            : 'Hora guardada para el recordatorio',
      );
    } catch (e) {
      if (!mounted) return;
      _showFloatingSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isReminderLoading = false;
        });
      }
    }
  }

  /// Tarjeta UI del recordatorio semanal.
  ///
  /// Muestra el estado actual, el switch de activación y la opción para
  /// modificar la hora sin salir de la pantalla de progreso.
  Widget _buildWeeklyReminderCard() {
    final subtitle = _weeklyReminderSettings.enabled
        ? 'Cada lunes a las ${_formatReminderTime(_weeklyReminderSettings)}'
        : 'Actívalo para no olvidar tu registro semanal';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.notifications_active_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recordatorio semanal',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _weeklyReminderSettings.enabled,
                  onChanged: _isReminderLoading ? null : _toggleWeeklyReminder,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              kIsWeb
                  ? 'En web solo se guarda la configuración. La notificación real se usa en móvil y escritorio.'
                  : 'XaFit te avisará para registrar tu peso de la semana.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _isReminderLoading ? null : _pickWeeklyReminderTime,
              icon: const Icon(Icons.schedule_outlined),
              label: Text(
                'Cambiar hora (${_formatReminderTime(_weeklyReminderSettings)})',
              ),
            ),
            if (_isReminderLoading) ...[
              const SizedBox(height: 14),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showAddEntryDialog() async {
    final entry = await showDialog<BodyProgressEntry>(
      context: context,
      builder: (_) => const _BodyProgressEntryDialog(),
    );

    if (entry == null) return;

    await _progressService.saveEntry(entry);
    await _refresh();

    if (!mounted) return;
    _showFloatingSnackBar('Registro guardado');
  }

  Future<void> _showEditEntryDialog(BodyProgressEntry entry) async {
    final updatedEntry = await showDialog<BodyProgressEntry>(
      context: context,
      builder: (_) => _BodyProgressEntryDialog(existing: entry),
    );

    if (updatedEntry == null) return;

    await _progressService.saveEntry(updatedEntry);
    await _refresh();

    if (!mounted) return;
    _showFloatingSnackBar('Registro actualizado');
  }

  Future<void> _deleteEntry(BodyProgressEntry entry) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Eliminar registro'),
              content: Text(
                'Se eliminará el registro del ${_formatDate(entry.date)}.',
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

    await _progressService.deleteEntry(entry.id);
    await _refresh();

    if (!mounted) return;
    _showFloatingSnackBar('Registro eliminado');
  }

  Future<void> _showEditProfileDialog() async {
    final updatedProfile = await showDialog<BodyProfile>(
      context: context,
      builder: (_) => _EditProfileDialog(profile: _profile),
    );

    if (updatedProfile == null) return;

    await _progressService.saveProfile(updatedProfile);
    await _refresh();

    if (!mounted) return;
    _showFloatingSnackBar('Perfil actualizado');
  }

  String _formatDouble(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  double? _metricValue(BodyProgressEntry entry, _ProgressMetric metric) {
    switch (metric) {
      case _ProgressMetric.weight:
        return entry.weight;
      case _ProgressMetric.waist:
        return entry.waist;
      case _ProgressMetric.chest:
        return entry.chest;
      case _ProgressMetric.arm:
        return entry.arm;
      case _ProgressMetric.thigh:
        return entry.thigh;
      case _ProgressMetric.bodyFat:
        return entry.bodyFat;
    }
  }

  String _metricLabel(_ProgressMetric metric) {
    switch (metric) {
      case _ProgressMetric.weight:
        return 'Peso';
      case _ProgressMetric.waist:
        return 'Cintura';
      case _ProgressMetric.chest:
        return 'Pecho';
      case _ProgressMetric.arm:
        return 'Brazo';
      case _ProgressMetric.thigh:
        return 'Pierna';
      case _ProgressMetric.bodyFat:
        return '% Grasa';
    }
  }

  String _metricUnit(_ProgressMetric metric) {
    switch (metric) {
      case _ProgressMetric.bodyFat:
        return '%';
      case _ProgressMetric.weight:
        return 'kg';
      case _ProgressMetric.waist:
      case _ProgressMetric.chest:
      case _ProgressMetric.arm:
      case _ProgressMetric.thigh:
        return 'cm';
    }
  }

  double? get _latestWeight {
    if (_entries.isEmpty) return null;
    return _entries.last.weight;
  }

  double? get _firstWeight {
    if (_entries.isEmpty) return null;
    return _entries.first.weight;
  }

  double? get _weightDelta {
    final first = _firstWeight;
    final latest = _latestWeight;
    if (first == null || latest == null) return null;
    return latest - first;
  }

  double? get _lastWeightChange {
    if (_entries.length < 2) return null;
    return _entries.last.weight - _entries[_entries.length - 2].weight;
  }

  double? get _targetWeightDelta {
    final latest = _latestWeight;
    final target = _profile.targetWeight;
    if (latest == null || target == null) return null;
    return latest - target;
  }

  int get _entriesLast30Days {
    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 30));

    return _entries.where((entry) {
      final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
      return !date.isBefore(cutoff);
    }).length;
  }

  int? get _daysSinceLastEntry {
    if (_entries.isEmpty) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = _entries.last.date;
    final lastDay = DateTime(last.year, last.month, last.day);

    return today.difference(lastDay).inDays;
  }

  double? get _latestBodyFat {
    for (final entry in _entries.reversed) {
      if (entry.bodyFat != null) return entry.bodyFat;
    }
    return null;
  }

  double? get _latestWaist {
    for (final entry in _entries.reversed) {
      if (entry.waist != null) return entry.waist;
    }
    return null;
  }

  List<_ChartPoint> get _chartPoints {
    final points = <_ChartPoint>[];

    for (final entry in _entries) {
      final value = _metricValue(entry, _selectedMetric);
      if (value != null) {
        points.add(_ChartPoint(date: entry.date, value: value));
      }
    }

    return points;
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E2A44), Color(0xFF203A43)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                child: Text(
                  (_profile.alias.isNotEmpty ? _profile.alias[0] : 'U')
                      .toUpperCase(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _profile.alias.isEmpty ? 'Usuario' : _profile.alias,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _profile.goal.isEmpty ? 'Sin objetivo' : _profile.goal,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _showEditProfileDialog,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(
                label: 'Altura',
                value: _profile.heightCm == null
                    ? '—'
                    : '${_formatDouble(_profile.heightCm!)} cm',
              ),
              _InfoChip(
                label: 'Peso objetivo',
                value: _profile.targetWeight == null
                    ? '—'
                    : '${_formatDouble(_profile.targetWeight!)} kg',
              ),
              _InfoChip(
                label: 'Edad',
                value: _profile.age == null ? '—' : '${_profile.age}',
              ),
              _InfoChip(label: 'Registros', value: '${_entries.length}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final latestWeight = _latestWeight;
    final latestBodyFat = _latestBodyFat;
    final delta = _weightDelta;
    final targetDelta = _targetWeightDelta;
    final lastWeightChange = _lastWeightChange;
    final daysSinceLastEntry = _daysSinceLastEntry;
    final recentEntries = _entriesLast30Days;

    final cards = [
      _MetricCard(
        title: 'Peso actual',
        value: latestWeight == null ? '—' : '${_formatDouble(latestWeight)} kg',
        subtitle: _entries.isEmpty ? 'Sin registros' : 'Última medición',
        icon: Icons.monitor_weight_outlined,
      ),
      _MetricCard(
        title: 'Cambio total',
        value: delta == null
            ? '—'
            : '${delta > 0 ? '+' : ''}${_formatDouble(delta)} kg',
        subtitle:
            _entries.length < 2 ? 'Faltan datos' : 'Desde el primer registro',
        icon: Icons.trending_up_rounded,
      ),
      _MetricCard(
        title: 'Último cambio',
        value: lastWeightChange == null
            ? '—'
            : '${lastWeightChange > 0 ? '+' : ''}${_formatDouble(lastWeightChange)} kg',
        subtitle: _entries.length < 2
            ? 'Solo hay una medición'
            : 'Frente al registro anterior',
        icon: Icons.show_chart_rounded,
      ),
      _MetricCard(
        title: 'Objetivo',
        value: targetDelta == null
            ? '—'
            : '${targetDelta > 0 ? '+' : ''}${_formatDouble(targetDelta)} kg',
        subtitle: _profile.targetWeight == null
            ? 'Sin peso objetivo'
            : 'Distancia al objetivo',
        icon: Icons.flag_outlined,
      ),
      _MetricCard(
        title: 'Registros 30 días',
        value: '$recentEntries',
        subtitle:
            recentEntries == 0 ? 'Sin actividad reciente' : 'Últimos 30 días',
        icon: Icons.event_note_rounded,
      ),
      _MetricCard(
        title: 'Último check-in',
        value: daysSinceLastEntry == null
            ? '—'
            : daysSinceLastEntry == 0
                ? 'Hoy'
                : '$daysSinceLastEntry d',
        subtitle: daysSinceLastEntry == null
            ? 'Sin registros'
            : daysSinceLastEntry <= 7
                ? 'Buen ritmo'
                : 'Conviene actualizar',
        icon: Icons.schedule_rounded,
      ),
      _MetricCard(
        title: '% Grasa',
        value: latestBodyFat == null ? '—' : '${_formatDouble(latestBodyFat)}%',
        subtitle: latestBodyFat == null ? 'No registrada' : 'Última medición',
        icon: Icons.percent_rounded,
      ),
      _MetricCard(
        title: 'Cintura',
        value:
            _latestWaist == null ? '—' : '${_formatDouble(_latestWaist!)} cm',
        subtitle: _latestWaist == null ? 'No registrada' : 'Última medición',
        icon: Icons.straighten_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 380;

        return GridView.count(
          crossAxisCount: isCompact ? 1 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: isCompact ? 2.5 : 1.45,
          children: cards,
        );
      },
    );
  }

  Widget _buildBackupCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.shield_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Backup y restauración',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Exporta una copia antes de cambiar mucho tus datos o de probar una build nueva.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: _exportBackup,
                  icon: const Icon(Icons.ios_share_rounded),
                  label: const Text('Exportar backup'),
                ),
                OutlinedButton.icon(
                  onPressed: _confirmImportBackup,
                  icon: const Icon(Icons.file_upload_outlined),
                  label: const Text('Importar backup'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Consejo: exporta un backup antes de importar otro archivo para tener una copia de seguridad rápida.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.62),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: DropdownButtonFormField<_ProgressMetric>(
          initialValue: _selectedMetric,
          decoration: const InputDecoration(labelText: 'Métrica de la gráfica'),
          items: _ProgressMetric.values.map((metric) {
            return DropdownMenuItem(
              value: metric,
              child: Text(_metricLabel(metric)),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedMetric = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    final points = _chartPoints;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Evolución de ${_metricLabel(_selectedMetric)}',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              points.isEmpty
                  ? 'Aún no hay datos para esta métrica'
                  : '${points.length} registros disponibles',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.70)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: points.isEmpty
                  ? Center(
                      child: Text(
                        'Añade registros para ver la gráfica',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.70),
                        ),
                      ),
                    )
                  : _MiniLineChart(
                      points: points,
                      unit: _metricUnit(_selectedMetric),
                      formatDouble: _formatDouble,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Historial',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (_entries.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 14),
                child: Text(
                  'Todavía no tienes registros corporales.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.70)),
                ),
              )
            else
              ListView.separated(
                itemCount: _entries.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (_, __) => Divider(
                  height: 18,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                itemBuilder: (context, index) {
                  final entry = _entries[_entries.length - 1 - index];

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.monitor_heart_outlined),
                    ),
                    title: Text(
                      '${_formatDouble(entry.weight)} kg',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _HistoryTag(label: _formatDate(entry.date)),
                          if (entry.waist != null)
                            _HistoryTag(
                              label:
                                  'Cintura ${_formatDouble(entry.waist!)} cm',
                            ),
                          if (entry.chest != null)
                            _HistoryTag(
                              label: 'Pecho ${_formatDouble(entry.chest!)} cm',
                            ),
                          if (entry.arm != null)
                            _HistoryTag(
                              label: 'Brazo ${_formatDouble(entry.arm!)} cm',
                            ),
                          if (entry.thigh != null)
                            _HistoryTag(
                              label: 'Pierna ${_formatDouble(entry.thigh!)} cm',
                            ),
                          if (entry.bodyFat != null)
                            _HistoryTag(
                              label: 'Grasa ${_formatDouble(entry.bodyFat!)}%',
                            ),
                        ],
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditEntryDialog(entry);
                        } else if (value == 'delete') {
                          _deleteEntry(entry);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Editar registro'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Eliminar registro'),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insights_outlined,
              size: 64,
              color: Colors.white.withValues(alpha: 0.75),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aún no hay progreso registrado',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Guarda tu primer peso o medición corporal para empezar a ver tu evolución.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _showAddEntryDialog,
              icon: const Icon(Icons.add),
              label: const Text('Añadir primer registro'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasEntries = _entries.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progreso'),
        actions: [
          IconButton(
            tooltip: 'Importar backup',
            onPressed: _confirmImportBackup,
            icon: const Icon(Icons.file_upload_outlined),
          ),
          IconButton(
            tooltip: 'Exportar backup',
            onPressed: _exportBackup,
            icon: const Icon(Icons.ios_share_rounded),
          ),
          IconButton(
            tooltip: 'Editar perfil',
            onPressed: _showEditProfileDialog,
            icon: const Icon(Icons.person_outline_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEntryDialog,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo registro'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildProfileCard(),
                  const SizedBox(height: 16),
                  if (hasEntries) ...[
                    _buildChartCard(),
                    const SizedBox(height: 16),
                    _buildMetricSelector(),
                    const SizedBox(height: 16),
                    _buildSummaryCards(),
                    const SizedBox(height: 16),
                  ],
                  _buildWeeklyReminderCard(),
                  const SizedBox(height: 16),
                  _buildBackupCard(),
                  const SizedBox(height: 16),
                  if (!hasEntries)
                    _buildEmptyState()
                  else ...[
                    _buildHistoryCard(),
                    const SizedBox(height: 90),
                  ],
                ],
              ),
            ),
    );
  }
}

enum _ProgressMetric { weight, waist, chest, arm, thigh, bodyFat }

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 22),
            const SizedBox(height: 14),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.62),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTag extends StatelessWidget {
  final String label;

  const _HistoryTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }
}

class _ChartPoint {
  final DateTime date;
  final double value;

  const _ChartPoint({required this.date, required this.value});
}

class _MiniLineChart extends StatelessWidget {
  final List<_ChartPoint> points;
  final String unit;
  final String Function(double value) formatDouble;

  const _MiniLineChart({
    required this.points,
    required this.unit,
    required this.formatDouble,
  });

  @override
  Widget build(BuildContext context) {
    final values = points.map((e) => e.value).toList();
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final latest = points.last.value;
    final first = points.first.value;

    final minDate = points.first.date;
    final maxDate = points.last.date;

    return Column(
      children: [
        Row(
          children: [
            _ChartLegendItem(
              label: 'Inicio',
              value: '${formatDouble(first)} $unit',
            ),
            const SizedBox(width: 12),
            _ChartLegendItem(
              label: 'Último',
              value: '${formatDouble(latest)} $unit',
            ),
            const Spacer(),
            Text(
              '${minDate.day}/${minDate.month} - ${maxDate.day}/${maxDate.month}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Expanded(
          child: CustomPaint(
            painter: _LineChartPainter(points: points),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white.withValues(alpha: 0.02),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _AxisLabel(
                    text: '${formatDouble(maxValue)} $unit',
                    alignLeft: true,
                  ),
                  const Spacer(),
                  _AxisLabel(
                    text: '${formatDouble((minValue + maxValue) / 2)} $unit',
                    alignLeft: true,
                  ),
                  const Spacer(),
                  _AxisLabel(
                    text: '${formatDouble(minValue)} $unit',
                    alignLeft: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChartLegendItem extends StatelessWidget {
  final String label;
  final String value;

  const _ChartLegendItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.68),
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _AxisLabel extends StatelessWidget {
  final String text;
  final bool alignLeft;

  const _AxisLabel({required this.text, required this.alignLeft});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: Colors.white.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<_ChartPoint> points;

  const _LineChartPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const horizontalPadding = 28.0;
    const topPadding = 18.0;
    const bottomPadding = 20.0;

    final chartWidth = size.width - horizontalPadding * 2;
    final chartHeight = size.height - topPadding - bottomPadding;

    if (chartWidth <= 0 || chartHeight <= 0) return;

    final values = points.map((e) => e.value).toList();
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range =
        (maxValue - minValue).abs() < 0.0001 ? 1.0 : (maxValue - minValue);

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;

    for (int i = 0; i < 3; i++) {
      final y = topPadding + (chartHeight / 2) * i;
      canvas.drawLine(
        Offset(horizontalPadding, y),
        Offset(horizontalPadding + chartWidth, y),
        gridPaint,
      );
    }

    final pointOffsets = <Offset>[];

    for (int i = 0; i < points.length; i++) {
      final x = points.length == 1
          ? horizontalPadding + chartWidth / 2
          : horizontalPadding + (chartWidth * i / (points.length - 1));

      final normalized = (points[i].value - minValue) / range;
      final y = topPadding + chartHeight - (normalized * chartHeight);

      pointOffsets.add(Offset(x, y));
    }

    if (pointOffsets.length >= 2) {
      final fillPath = Path()
        ..moveTo(pointOffsets.first.dx, topPadding + chartHeight);

      for (final point in pointOffsets) {
        fillPath.lineTo(point.dx, point.dy);
      }

      fillPath
        ..lineTo(pointOffsets.last.dx, topPadding + chartHeight)
        ..close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.lightBlueAccent.withValues(alpha: 0.25),
            Colors.lightBlueAccent.withValues(alpha: 0.02),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(
          Rect.fromLTWH(
            horizontalPadding,
            topPadding,
            chartWidth,
            chartHeight,
          ),
        );

      canvas.drawPath(fillPath, fillPaint);
    }

    final linePaint = Paint()
      ..color = Colors.lightBlueAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (pointOffsets.length == 1) {
      canvas.drawCircle(
        pointOffsets.first,
        4,
        Paint()..color = Colors.lightBlueAccent,
      );
    } else {
      final path = Path()..moveTo(pointOffsets.first.dx, pointOffsets.first.dy);

      for (int i = 1; i < pointOffsets.length; i++) {
        path.lineTo(pointOffsets[i].dx, pointOffsets[i].dy);
      }

      canvas.drawPath(path, linePaint);
    }

    final dotPaint = Paint()..color = Colors.white;
    final dotBorderPaint = Paint()..color = Colors.lightBlueAccent;

    for (final point in pointOffsets) {
      canvas.drawCircle(point, 5, dotBorderPaint);
      canvas.drawCircle(point, 2.6, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    if (oldDelegate.points.length != points.length) return true;

    for (int i = 0; i < points.length; i++) {
      if (oldDelegate.points[i].value != points[i].value ||
          oldDelegate.points[i].date != points[i].date) {
        return true;
      }
    }

    return false;
  }
}

class _EditProfileDialog extends StatefulWidget {
  final BodyProfile profile;

  const _EditProfileDialog({required this.profile});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _aliasController;
  late final TextEditingController _heightController;
  late final TextEditingController _targetWeightController;
  late final TextEditingController _ageController;

  late String _selectedGoal;

  static const _goals = [
    'Mantenimiento',
    'Bajar grasa',
    'Subir masa',
    'Definición',
  ];

  @override
  void initState() {
    super.initState();
    _aliasController = TextEditingController(text: widget.profile.alias);
    _heightController = TextEditingController(
      text: widget.profile.heightCm?.toString() ?? '',
    );
    _targetWeightController = TextEditingController(
      text: widget.profile.targetWeight?.toString() ?? '',
    );
    _ageController = TextEditingController(
      text: widget.profile.age?.toString() ?? '',
    );
    _selectedGoal = _goals.contains(widget.profile.goal)
        ? widget.profile.goal
        : _goals.first;
  }

  @override
  void dispose() {
    _aliasController.dispose();
    _heightController.dispose();
    _targetWeightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  double? _parseOptionalDouble(String raw) {
    final value = raw.trim().replaceAll(',', '.');
    if (value.isEmpty) return null;
    return double.tryParse(value);
  }

  int? _parseOptionalInt(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    return int.tryParse(value);
  }

  void _save() {
    FocusScope.of(context).unfocus();

    final profile = BodyProfile(
      alias: _aliasController.text.trim().isEmpty
          ? 'Usuario'
          : _aliasController.text.trim(),
      goal: _selectedGoal,
      heightCm: _parseOptionalDouble(_heightController.text),
      targetWeight: _parseOptionalDouble(_targetWeightController.text),
      age: _parseOptionalInt(_ageController.text),
    );

    Navigator.of(context).pop(profile);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar perfil'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _aliasController,
              decoration: const InputDecoration(labelText: 'Alias'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedGoal,
              decoration: const InputDecoration(labelText: 'Objetivo'),
              items: _goals.map((goal) {
                return DropdownMenuItem(value: goal, child: Text(goal));
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedGoal = value;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _heightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Altura (cm)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _targetWeightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Peso objetivo (kg)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Edad'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }
}

class _BodyProgressEntryDialog extends StatefulWidget {
  final BodyProgressEntry? existing;

  const _BodyProgressEntryDialog({this.existing});

  @override
  State<_BodyProgressEntryDialog> createState() =>
      _BodyProgressEntryDialogState();
}

class _BodyProgressEntryDialogState extends State<_BodyProgressEntryDialog> {
  late final TextEditingController _weightController;
  late final TextEditingController _waistController;
  late final TextEditingController _chestController;
  late final TextEditingController _armController;
  late final TextEditingController _thighController;
  late final TextEditingController _bodyFatController;

  late DateTime _selectedDate;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;

    _selectedDate = existing?.date ?? DateTime.now();
    _weightController = TextEditingController(
      text: existing?.weight.toString() ?? '',
    );
    _waistController = TextEditingController(
      text: existing?.waist?.toString() ?? '',
    );
    _chestController = TextEditingController(
      text: existing?.chest?.toString() ?? '',
    );
    _armController = TextEditingController(
      text: existing?.arm?.toString() ?? '',
    );
    _thighController = TextEditingController(
      text: existing?.thigh?.toString() ?? '',
    );
    _bodyFatController = TextEditingController(
      text: existing?.bodyFat?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _waistController.dispose();
    _chestController.dispose();
    _armController.dispose();
    _thighController.dispose();
    _bodyFatController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  double? _parseOptional(String raw) {
    final value = raw.trim().replaceAll(',', '.');
    if (value.isEmpty) return null;
    return double.tryParse(value);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked == null) return;

    setState(() {
      _selectedDate = picked;
    });
  }

  void _save() {
    FocusScope.of(context).unfocus();

    final weight = _parseOptional(_weightController.text);

    if (weight == null || weight <= 0) {
      setState(() {
        _errorText = 'Introduce un peso válido';
      });
      return;
    }

    final entry = BodyProgressEntry(
      id: widget.existing?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      date: _selectedDate,
      weight: weight,
      waist: _parseOptional(_waistController.text),
      chest: _parseOptional(_chestController.text),
      arm: _parseOptional(_armController.text),
      thigh: _parseOptional(_thighController.text),
      bodyFat: _parseOptional(_bodyFatController.text),
    );

    Navigator.of(context).pop(entry);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return AlertDialog(
      title: Text(
        isEditing ? 'Editar registro corporal' : 'Nuevo registro corporal',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Fecha'),
                child: Row(
                  children: [
                    Expanded(child: Text(_formatDate(_selectedDate))),
                    const Icon(Icons.calendar_today_rounded, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Peso (kg) *',
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
              controller: _waistController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Cintura (cm)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _chestController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Pecho (cm)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _armController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Brazo (cm)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _thighController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Pierna (cm)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyFatController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: '% Grasa'),
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
          child: Text(isEditing ? 'Guardar cambios' : 'Guardar'),
        ),
      ],
    );
  }
}
