import 'package:flutter/material.dart';
import 'package:poker_analyzer/services/preferences_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LessonPathReminderScheduler {
  LessonPathReminderScheduler._();
  static final LessonPathReminderScheduler instance = LessonPathReminderScheduler._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _hourKey = 'lesson_path_reminder_hour';
  static const _minuteKey = 'lesson_path_reminder_minute';
  static const _enabledKey = 'lesson_path_reminder_enabled';
  static const _id = 222;

  Future<void> _init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
    tz.initializeTimeZones();
    _initialized = true;
  }

  Future<TimeOfDay?> getScheduledTime() async {
    final prefs = await PreferencesService.getInstance();
    final enabled = prefs.getBool(_enabledKey) ?? false;
    if (!enabled) return null;
    final hour = prefs.getInt(_hourKey) ?? 19;
    final minute = prefs.getInt(_minuteKey) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> scheduleReminder({required TimeOfDay time}) async {
    await _init();
    final prefs = await PreferencesService.getInstance();
    await prefs.setInt(_hourKey, time.hour);
    await prefs.setInt(_minuteKey, time.minute);
    await prefs.setBool(_enabledKey, true);

    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (!when.isAfter(now)) {
      when = when.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _id,
      'Poker Analyzer',
      '🧠 Не забудьте пройти шаг обучения сегодня!',
      when,
      const NotificationDetails(
        android: AndroidNotificationDetails('lesson_path_reminder', 'Lesson Path Reminder'),
        iOS: DarwinNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> sendTestReminder() async {
    await _init();
    await _plugin.show(
      _id,
      'Poker Analyzer',
      '🧠 Не забудьте пройти шаг обучения сегодня!',
      const NotificationDetails(
        android: AndroidNotificationDetails('lesson_path_reminder', 'Lesson Path Reminder'),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> cancelReminder() async {
    await _init();
    await _plugin.cancel(_id);
    final prefs = await PreferencesService.getInstance();
    await prefs.setBool(_enabledKey, false);
  }
}
