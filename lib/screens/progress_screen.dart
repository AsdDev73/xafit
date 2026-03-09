import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/body_profile.dart';
import '../models/body_progress_entry.dart';
import '../services/app_repositories.dart';
import '../services/notification_service.dart';
import '../services/progress_service.dart';

enum ProgressMetric { weight, waist, chest, arm, thigh, bodyFat }

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final ProgressService _progressService = ProgressService(
    bodyProfileRepository: AppRepositories.bodyProfile,
    bodyProgressRepository: AppRepositories.bodyProgress,
  );

  List<BodyProgressEntry> _entries = [];
  BodyProfile _profile = BodyProfile.empty;
  bool _isLoading = true;
  ProgressMetric _selectedMetric = ProgressMetric.weight;
  WeeklyReminderSettings _reminderSettings =
      const WeeklyReminderSettings.defaultValue();

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
    });

    final overview = await _progressService.loadOverview();

    if (!mounted) return;

    setState(() {
      _entries = overview.entries;
      _profile = overview.profile;
      _reminderSettings = overview.reminderSettings;
      _isLoading = false;
    });
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  String _formatDouble(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  String _formatTime(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _metricLabel(ProgressMetric metric) {
    switch (metric) {
      case ProgressMetric.weight:
        return 'Peso';
      case ProgressMetric.waist:
        return 'Cintura';
      case ProgressMetric.chest:
        return 'Pecho';
      case ProgressMetric.arm:
        return 'Brazo';
      case ProgressMetric.thigh:
        return 'Pierna';
      case ProgressMetric.bodyFat:
        return '% Grasa';
    }
  }

  double? _metricValue(BodyProgressEntry entry, ProgressMetric metric) {
    switch (metric) {
      case ProgressMetric.weight:
        return entry.weight;
      case ProgressMetric.waist:
        return entry.waist;
      case ProgressMetric.chest:
        return entry.chest;
      case ProgressMetric.arm:
        return entry.arm;
      case ProgressMetric.thigh:
        return entry.thigh;
      case ProgressMetric.bodyFat:
        return entry.bodyFat;
    }
  }

  String _formatMetricValue(ProgressMetric metric, double value) {
    if (metric == ProgressMetric.weight) {
      return '${_formatDouble(value)} kg';
    }

    if (metric == ProgressMetric.bodyFat) {
      return '${_formatDouble(value)} %';
    }

    return '${_formatDouble(value)} cm';
  }

  List<BodyProgressEntry> _entriesForMetric(ProgressMetric metric) {
    final filtered = _entries
        .where((entry) => _metricValue(entry, metric) != null)
        .toList();

    filtered.sort((a, b) => a.date.compareTo(b.date));
    return filtered;
  }

  Widget _buildStatCard({required String label, required String value}) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.75),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeasureChip(String label, double value, {String suffix = 'cm'}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label ${_formatDouble(value)} $suffix',
        style: const TextStyle(fontSize: 11),
      ),
    );
  }

  Widget _buildProfileChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$label: $value', style: const TextStyle(fontSize: 11)),
    );
  }

  Widget _buildEntryCard(BodyProgressEntry entry) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatDate(entry.date),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${_formatDouble(entry.weight)} kg',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (entry.waist != null)
                    _buildMeasureChip('Cintura', entry.waist!),
                  if (entry.chest != null)
                    _buildMeasureChip('Pecho', entry.chest!),
                  if (entry.arm != null) _buildMeasureChip('Brazo', entry.arm!),
                  if (entry.thigh != null)
                    _buildMeasureChip('Pierna', entry.thigh!),
                  if (entry.bodyFat != null)
                    _buildMeasureChip('% Grasa', entry.bodyFat!, suffix: '%'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestMeasuresCard() {
    if (_entries.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            'Todavía no hay medidas para mostrar',
            style: TextStyle(color: Colors.white.withOpacity(0.75)),
          ),
        ),
      );
    }

    final latest = _entries.first;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Último registro corporal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              _formatDate(latest.date),
              style: TextStyle(color: Colors.white.withOpacity(0.75)),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildMeasureChip('Peso', latest.weight, suffix: 'kg'),
                if (latest.waist != null)
                  _buildMeasureChip('Cintura', latest.waist!),
                if (latest.chest != null)
                  _buildMeasureChip('Pecho', latest.chest!),
                if (latest.arm != null) _buildMeasureChip('Brazo', latest.arm!),
                if (latest.thigh != null)
                  _buildMeasureChip('Pierna', latest.thigh!),
                if (latest.bodyFat != null)
                  _buildMeasureChip('% Grasa', latest.bodyFat!, suffix: '%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ProgressMetric.values.map((metric) {
        final selected = _selectedMetric == metric;
        return ChoiceChip(
          selected: selected,
          label: Text(_metricLabel(metric)),
          onSelected: (_) {
            setState(() {
              _selectedMetric = metric;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildMetricChart() {
    final filtered = _entriesForMetric(_selectedMetric);

    if (filtered.length < 2) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: SizedBox(
            height: 240,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Evolución de ${_metricLabel(_selectedMetric).toLowerCase()}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Necesitas al menos 2 registros con ese dato',
                  style: TextStyle(color: Colors.white.withOpacity(0.75)),
                ),
                const Spacer(),
                Center(
                  child: Text(
                    'Aún no hay suficientes datos',
                    style: TextStyle(color: Colors.white.withOpacity(0.70)),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      );
    }

    final spots = List.generate(filtered.length, (index) {
      final value = _metricValue(filtered[index], _selectedMetric)!;
      return FlSpot(index.toDouble(), value);
    });

    double minY = spots.first.y;
    double maxY = spots.first.y;

    for (final spot in spots) {
      if (spot.y < minY) minY = spot.y;
      if (spot.y > maxY) maxY = spot.y;
    }

    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    } else {
      final padding = (maxY - minY) * 0.15;
      minY -= padding;
      maxY += padding;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: SizedBox(
          height: 280,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Evolución de ${_metricLabel(_selectedMetric).toLowerCase()}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Último valor: ${_formatMetricValue(_selectedMetric, spots.last.y)}',
                style: TextStyle(color: Colors.white.withOpacity(0.75)),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: LineChart(
                  LineChartData(
                    minY: minY,
                    maxY: maxY,
                    gridData: FlGridData(
                      show: true,
                      horizontalInterval: (maxY - minY) / 4,
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 48,
                          getTitlesWidget: (value, meta) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                _formatDouble(value),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withOpacity(0.70),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          reservedSize: 32,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= filtered.length) {
                              return const SizedBox.shrink();
                            }

                            final date = filtered[idx].date;
                            final label =
                                '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withOpacity(0.70),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (spots) {
                          return spots.map((spot) {
                            return LineTooltipItem(
                              _formatMetricValue(_selectedMetric, spot.y),
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReminderCard() {
    final reminderText =
        'Cada lunes a las ${_formatTime(_reminderSettings.hour, _reminderSettings.minute)}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recordatorio semanal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              reminderText,
              style: TextStyle(color: Colors.white.withOpacity(0.75)),
            ),
            const SizedBox(height: 6),
            Text(
              _reminderSettings.enabled ? 'Activo' : 'Desactivado',
              style: TextStyle(
                color: _reminderSettings.enabled
                    ? Colors.lightGreenAccent
                    : Colors.white.withOpacity(0.70),
              ),
            ),
            const SizedBox(height: 14),
            if (kIsWeb)
              Text(
                'La configuración se guarda, pero la notificación real tendrás que probarla en Android o iPhone.',
                style: TextStyle(color: Colors.white.withOpacity(0.75)),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickReminderTime,
                      icon: const Icon(Icons.schedule_rounded),
                      label: const Text('Cambiar hora'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _toggleReminder,
                      icon: Icon(
                        _reminderSettings.enabled
                            ? Icons.notifications_off_rounded
                            : Icons.notifications_active_rounded,
                      ),
                      label: Text(
                        _reminderSettings.enabled ? 'Desactivar' : 'Activar',
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _reminderSettings.hour,
        minute: _reminderSettings.minute,
      ),
    );

    if (picked == null) return;

    await NotificationService.saveWeeklyReminderTime(
      hour: picked.hour,
      minute: picked.minute,
    );

    if (_reminderSettings.enabled) {
      try {
        await NotificationService.scheduleWeeklyWeightReminder(
          hour: picked.hour,
          minute: picked.minute,
          requestPermission: false,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Recordatorio cambiado a ${_formatTime(picked.hour, picked.minute)}',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo actualizar el recordatorio: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    await _refresh();
  }

  Future<void> _toggleReminder() async {
    try {
      if (_reminderSettings.enabled) {
        await NotificationService.cancelWeeklyWeightReminder();
      } else {
        await NotificationService.scheduleWeeklyWeightReminder(
          hour: _reminderSettings.hour,
          minute: _reminderSettings.minute,
        );
      }

      await _refresh();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _reminderSettings.enabled
                ? 'Recordatorio desactivado'
                : 'Recordatorio activado',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo cambiar el recordatorio: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showEditProfileDialog() async {
    final aliasController = TextEditingController(text: _profile.alias);
    final heightController = TextEditingController(
      text: _profile.heightCm != null ? _formatDouble(_profile.heightCm!) : '',
    );
    final targetWeightController = TextEditingController(
      text: _profile.targetWeight != null
          ? _formatDouble(_profile.targetWeight!)
          : '',
    );
    final ageController = TextEditingController(
      text: _profile.age != null ? '${_profile.age}' : '',
    );

    String selectedGoal = _profile.goal;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Editar perfil'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: aliasController,
                      decoration: const InputDecoration(labelText: 'Alias'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedGoal,
                      items: const [
                        DropdownMenuItem(
                          value: 'Mantenimiento',
                          child: Text('Mantenimiento'),
                        ),
                        DropdownMenuItem(
                          value: 'Bajar grasa',
                          child: Text('Bajar grasa'),
                        ),
                        DropdownMenuItem(
                          value: 'Subir masa',
                          child: Text('Subir masa'),
                        ),
                        DropdownMenuItem(
                          value: 'Definición',
                          child: Text('Definición'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          selectedGoal = value;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Objetivo'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: heightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Altura (cm) · opcional',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: targetWeightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Peso objetivo (kg) · opcional',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Edad · opcional',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    double? parseOptionalDouble(
                      TextEditingController controller,
                    ) {
                      final text = controller.text.trim();
                      if (text.isEmpty) return null;
                      return double.tryParse(text.replaceAll(',', '.'));
                    }

                    int? parseOptionalInt(TextEditingController controller) {
                      final text = controller.text.trim();
                      if (text.isEmpty) return null;
                      return int.tryParse(text);
                    }

                    final alias = aliasController.text.trim().isEmpty
                        ? 'Usuario'
                        : aliasController.text.trim();

                    final newProfile = BodyProfile(
                      alias: alias,
                      goal: selectedGoal,
                      heightCm: parseOptionalDouble(heightController),
                      targetWeight: parseOptionalDouble(targetWeightController),
                      age: parseOptionalInt(ageController),
                    );

                    await _progressService.saveProfile(newProfile);

                    if (!mounted) return;
                    Navigator.pop(context);
                    await _refresh();

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Perfil actualizado'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    aliasController.dispose();
    heightController.dispose();
    targetWeightController.dispose();
    ageController.dispose();
  }

  Future<void> _showAddEntryDialog() async {
    final weightController = TextEditingController();
    final waistController = TextEditingController();
    final chestController = TextEditingController();
    final armController = TextEditingController();
    final thighController = TextEditingController();
    final bodyFatController = TextEditingController();

    DateTime selectedDate = DateTime.now();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );

              if (picked != null) {
                setDialogState(() {
                  selectedDate = picked;
                });
              }
            }

            return AlertDialog(
              title: const Text('Nuevo registro corporal'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Fecha'),
                        child: Row(
                          children: [
                            Expanded(child: Text(_formatDate(selectedDate))),
                            const Icon(Icons.calendar_today_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: weightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Peso (kg) *',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: waistController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Cintura (cm)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: chestController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Pecho (cm)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: armController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Brazo (cm)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: thighController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Pierna (cm)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bodyFatController,
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    final weight = double.tryParse(
                      weightController.text.trim().replaceAll(',', '.'),
                    );

                    if (weight == null || weight <= 0) {
                      return;
                    }

                    double? parseOptional(TextEditingController controller) {
                      final text = controller.text.trim();
                      if (text.isEmpty) return null;
                      return double.tryParse(text.replaceAll(',', '.'));
                    }

                    final entry = BodyProgressEntry(
                      id: DateTime.now().microsecondsSinceEpoch.toString(),
                      date: selectedDate,
                      weight: weight,
                      waist: parseOptional(waistController),
                      chest: parseOptional(chestController),
                      arm: parseOptional(armController),
                      thigh: parseOptional(thighController),
                      bodyFat: parseOptional(bodyFatController),
                    );

                    await _progressService.saveEntry(entry);

                    if (!mounted) return;
                    Navigator.pop(context);
                    await _refresh();

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Registro guardado'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    weightController.dispose();
    waistController.dispose();
    chestController.dispose();
    armController.dispose();
    thighController.dispose();
    bodyFatController.dispose();
  }

  Future<void> _clearAllEntries() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Borrar progreso'),
          content: const Text(
            'Esto eliminará todos los registros corporales guardados.',
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

    if (confirmed == true) {
      await _progressService.clearAllEntries();
      await _refresh();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Progreso borrado'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentWeight = _entries.isNotEmpty
        ? '${_formatDouble(_entries.first.weight)} kg'
        : '--';

    String changeText = '--';
    if (_entries.length >= 2) {
      final diff = _entries.first.weight - _entries[1].weight;
      final sign = diff > 0 ? '+' : '';
      changeText = '$sign${_formatDouble(diff)} kg';
    }

    final targetText = _profile.targetWeight != null
        ? '${_formatDouble(_profile.targetWeight!)} kg'
        : '--';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progreso'),
        actions: [
          IconButton(
            onPressed: _clearAllEntries,
            icon: const Icon(Icons.delete_sweep_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEntryDialog,
        icon: const Icon(Icons.add),
        label: const Text('Registro'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E2A44), Color(0xFF203A43)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _profile.alias,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Perfil y seguimiento corporal',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.90),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildProfileChip('Objetivo', _profile.goal),
                            if (_profile.heightCm != null)
                              _buildProfileChip(
                                'Altura',
                                '${_formatDouble(_profile.heightCm!)} cm',
                              ),
                            if (_profile.age != null)
                              _buildProfileChip('Edad', '${_profile.age}'),
                            if (_profile.targetWeight != null)
                              _buildProfileChip(
                                'Peso objetivo',
                                '${_formatDouble(_profile.targetWeight!)} kg',
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _showEditProfileDialog,
                            icon: const Icon(Icons.edit_rounded),
                            label: const Text('Editar perfil'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatCard(
                        label: 'Peso actual',
                        value: currentWeight,
                      ),
                      const SizedBox(width: 10),
                      _buildStatCard(label: 'Cambio', value: changeText),
                      const SizedBox(width: 10),
                      _buildStatCard(label: 'Objetivo', value: targetText),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildReminderCard(),
                  const SizedBox(height: 16),
                  _buildLatestMeasuresCard(),
                  const SizedBox(height: 16),
                  const Text(
                    'Gráfica',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _buildMetricSelector(),
                  const SizedBox(height: 12),
                  _buildMetricChart(),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Historial',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        'Peso y medidas',
                        style: TextStyle(color: Colors.white.withOpacity(0.75)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_entries.isEmpty)
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.40,
                      child: Center(
                        child: Text(
                          'Todavía no tienes registros.\nAñade tu primer peso.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                          ),
                        ),
                      ),
                    )
                  else
                    ..._entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildEntryCard(entry),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
