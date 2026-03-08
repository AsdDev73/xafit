import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class WeeklyReminderSettings {
  final bool enabled;
  final int hour;
  final int minute;

  const WeeklyReminderSettings({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  const WeeklyReminderSettings.defaultValue()
    : enabled = false,
      hour = 9,
      minute = 0;

  WeeklyReminderSettings copyWith({bool? enabled, int? hour, int? minute}) {
    return WeeklyReminderSettings(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _weeklyWeightReminderId = 1001;
  static const String _enabledKey = 'xafit_weekly_reminder_enabled';
  static const String _hourKey = 'xafit_weekly_reminder_hour';
  static const String _minuteKey = 'xafit_weekly_reminder_minute';

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    if (kIsWeb) {
      _initialized = true;
      return;
    }

    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
    } catch (_) {
      // Mantiene la localización por defecto si falla.
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(settings: settings);

    _initialized = true;

    final reminderSettings = await loadWeeklyReminderSettings();
    if (reminderSettings.enabled) {
      await scheduleWeeklyWeightReminder(
        hour: reminderSettings.hour,
        minute: reminderSettings.minute,
        requestPermission: false,
      );
    }
  }

  static Future<WeeklyReminderSettings> loadWeeklyReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final enabled = prefs.getBool(_enabledKey) ?? false;
    final hour = prefs.getInt(_hourKey) ?? 9;
    final minute = prefs.getInt(_minuteKey) ?? 0;

    return WeeklyReminderSettings(enabled: enabled, hour: hour, minute: minute);
  }

  static Future<void> _saveWeeklyReminderSettings(
    WeeklyReminderSettings settings,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, settings.enabled);
    await prefs.setInt(_hourKey, settings.hour);
    await prefs.setInt(_minuteKey, settings.minute);
  }

  static Future<void> saveWeeklyReminderTime({
    required int hour,
    required int minute,
  }) async {
    final current = await loadWeeklyReminderSettings();
    await _saveWeeklyReminderSettings(
      current.copyWith(hour: hour, minute: minute),
    );
  }

  static Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    await init();

    bool androidGranted = true;
    bool iosGranted = true;
    bool macGranted = true;

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      androidGranted =
          await androidPlugin.requestNotificationsPermission() ?? false;
    }

    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (iosPlugin != null) {
      iosGranted =
          await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    final macPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();

    if (macPlugin != null) {
      macGranted =
          await macPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return androidGranted && iosGranted && macGranted;
  }

  static tz.TZDateTime _nextMondayAt({required int hour, required int minute}) {
    final now = tz.TZDateTime.now(tz.local);

    int daysUntilMonday = (DateTime.monday - now.weekday) % 7;

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + daysUntilMonday,
      hour,
      minute,
    );

    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }

    return scheduled;
  }

  static Future<void> scheduleWeeklyWeightReminder({
    required int hour,
    required int minute,
    bool requestPermission = true,
  }) async {
    if (kIsWeb) {
      final current = await loadWeeklyReminderSettings();
      await _saveWeeklyReminderSettings(
        current.copyWith(enabled: true, hour: hour, minute: minute),
      );
      return;
    }

    await init();

    if (requestPermission) {
      final granted = await requestPermissions();
      if (!granted) {
        throw Exception('Permiso de notificaciones denegado.');
      }
    }

    await _plugin.cancel(id: _weeklyWeightReminderId);

    final scheduledDate = _nextMondayAt(hour: hour, minute: minute);

    const androidDetails = AndroidNotificationDetails(
      'xafit_weekly_reminders',
      'XaFit Weekly Reminders',
      channelDescription: 'Recordatorios semanales para registrar tu peso',
      importance: Importance.high,
      priority: Priority.high,
    );

    const darwinDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _plugin.zonedSchedule(
      id: _weeklyWeightReminderId,
      title: 'XaFit · registro semanal',
      body: 'Toca registrar tu peso de esta semana.',
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );

    await _saveWeeklyReminderSettings(
      WeeklyReminderSettings(enabled: true, hour: hour, minute: minute),
    );
  }

  static Future<void> cancelWeeklyWeightReminder() async {
    if (kIsWeb) {
      final current = await loadWeeklyReminderSettings();
      await _saveWeeklyReminderSettings(current.copyWith(enabled: false));
      return;
    }

    await init();
    await _plugin.cancel(id: _weeklyWeightReminderId);

    final current = await loadWeeklyReminderSettings();
    await _saveWeeklyReminderSettings(current.copyWith(enabled: false));
  }
}
