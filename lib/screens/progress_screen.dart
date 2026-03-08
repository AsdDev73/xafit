import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/body_profile_storage.dart';
import '../data/body_progress_storage.dart';
import '../models/body_profile.dart';
import '../models/body_progress_entry.dart';
import '../services/notification_service.dart';

enum ProgressMetric { weight, waist, chest, arm, thigh, bodyFat }

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
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

    final entries = await BodyProgressStorage.loadEntries();
    final profile = await BodyProfileStorage.loadProfile();
    final reminderSettings =
        await NotificationService.loadWeeklyReminderSettings();

    if (!mounted) return;

    setState(() {
      _entries = entries;
      _profile = profile;
      _reminderSettings = reminderSettings;
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
                    'Añade más registros para ver la gráfica',
                    style: TextStyle(color: Colors.white.withOpacity(0.70)),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < filtered.length; i++) {
      final value = _metricValue(filtered[i], _selectedMetric)!;
      spots.add(FlSpot(i.toDouble(), value));
    }

    double minY = _metricValue(filtered.first, _selectedMetric)!;
    double maxY = _metricValue(filtered.first, _selectedMetric)!;

    for (final entry in filtered) {
      final value = _metricValue(entry, _selectedMetric)!;
      if (value < minY) minY = value;
      if (value > maxY) maxY = value;
    }

    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    } else {
      minY -= 1;
      maxY += 1;
    }

    final latestValue = _metricValue(filtered.last, _selectedMetric)!;
    String changeText = '--';

    if (filtered.length >= 2) {
      final previousValue = _metricValue(
        filtered[filtered.length - 2],
        _selectedMetric,
      )!;
      final diff = latestValue - previousValue;
      final sign = diff > 0 ? '+' : '';
      final suffix = _selectedMetric == ProgressMetric.bodyFat
          ? '%'
          : _selectedMetric == ProgressMetric.weight
          ? 'kg'
          : 'cm';
      changeText = '$sign${_formatDouble(diff)} $suffix';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: SizedBox(
          height: 300,
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Actual: ${_formatMetricValue(_selectedMetric, latestValue)}',
                      style: TextStyle(color: Colors.white.withOpacity(0.75)),
                    ),
                  ),
                  Text(
                    changeText,
                    style: TextStyle(color: Colors.white.withOpacity(0.75)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: LineChart(
                  LineChartData(
                    minY: minY,
                    maxY: maxY,
                    gridData: FlGridData(show: true, drawVerticalLine: false),
                    borderData: FlBorderData(show: false),
                    lineTouchData: LineTouchData(
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final idx = spot.x.toInt();
                            final entry = filtered[idx];
                            final value = _metricValue(entry, _selectedMetric)!;
                            return LineTooltipItem(
                              '${_formatDate(entry.date)}\n${_formatMetricValue(_selectedMetric, value)}',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
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
                          reservedSize: 44,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toStringAsFixed(0),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.70),
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
          const SnackBar(
            content: Text('Hora del recordatorio actualizada'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo actualizar: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    await _refresh();
  }

  Future<void> _toggleReminder() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las notificaciones no están disponibles en web'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      if (_reminderSettings.enabled) {
        await NotificationService.cancelWeeklyWeightReminder();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recordatorio desactivado'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        await NotificationService.scheduleWeeklyWeightReminder(
          hour: _reminderSettings.hour,
          minute: _reminderSettings.minute,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Recordatorio activado para los lunes a las ${_formatTime(_reminderSettings.hour, _reminderSettings.minute)}',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo activar: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    await _refresh();
  }

  Future<void> _showEditProfileDialog() async {
    final aliasController = TextEditingController(text: _profile.alias);
    final heightController = TextEditingController(
      text: _profile.heightCm?.toString() ?? '',
    );
    final targetWeightController = TextEditingController(
      text: _profile.targetWeight?.toString() ?? '',
    );
    final ageController = TextEditingController(
      text: _profile.age?.toString() ?? '',
    );

    String selectedGoal = _profile.goal;
    const goals = ['Volumen', 'Definición', 'Mantenimiento'];

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
                      decoration: const InputDecoration(
                        labelText: 'Nombre o alias',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedGoal,
                      items: goals
                          .map(
                            (goal) => DropdownMenuItem(
                              value: goal,
                              child: Text(goal),
                            ),
                          )
                          .toList(),
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
                        labelText: 'Altura (cm) - opcional',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: targetWeightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Peso objetivo (kg) - opcional',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Edad - opcional',
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
                    double? parseOptionalDouble(String text) {
                      final value = text.trim();
                      if (value.isEmpty) return null;
                      return double.tryParse(value.replaceAll(',', '.'));
                    }

                    int? parseOptionalInt(String text) {
                      final value = text.trim();
                      if (value.isEmpty) return null;
                      return int.tryParse(value);
                    }

                    final profile = BodyProfile(
                      alias: aliasController.text.trim().isEmpty
                          ? 'Usuario'
                          : aliasController.text.trim(),
                      goal: selectedGoal,
                      heightCm: parseOptionalDouble(heightController.text),
                      targetWeight: parseOptionalDouble(
                        targetWeightController.text,
                      ),
                      age: parseOptionalInt(ageController.text),
                    );

                    await BodyProfileStorage.saveProfile(profile);

                    if (!mounted) return;
                    Navigator.pop(context);
                    await _refresh();

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Perfil guardado'),
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
            return AlertDialog(
              title: const Text('Nuevo registro'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );

                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('Fecha: ${_formatDate(selectedDate)}'),
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
                        hintText: 'Ejemplo: 78.4',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: waistController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Cintura (cm) - opcional',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: chestController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Pecho (cm) - opcional',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: armController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Brazo (cm) - opcional',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: thighController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Pierna (cm) - opcional',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bodyFatController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: '% grasa - opcional',
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

                    await BodyProgressStorage.saveEntry(entry);

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
      await BodyProgressStorage.clearAllEntries();
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
