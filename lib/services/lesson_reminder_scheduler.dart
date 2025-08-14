import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LessonReminderScheduler {
  LessonReminderScheduler._();
  static final LessonReminderScheduler instance = LessonReminderScheduler._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _hourKey = 'lesson_reminder_hour';
  static const _minuteKey = 'lesson_reminder_minute';
  static const _enabledKey = 'lesson_reminder_enabled';
  static const _id = 121;

  Future<void> _init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin
        .initialize(const InitializationSettings(android: android, iOS: ios));
    tz.initializeTimeZones();
    _initialized = true;
  }

  Future<TimeOfDay?> getScheduledTime() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_enabledKey) ?? false;
    if (!enabled) return null;
    final hour = prefs.getInt(_hourKey) ?? 19;
    final minute = prefs.getInt(_minuteKey) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> scheduleReminder({required TimeOfDay time}) async {
    await _init();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hourKey, time.hour);
    await prefs.setInt(_minuteKey, time.minute);
    await prefs.setBool(_enabledKey, true);

    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (!when.isAfter(now)) {
      when = when.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _id,
      '\uD83C\uDFC6 Don't forget your daily poker training!',
      'Complete your 5 hands and keep your streak alive \uD83D\uDD25',
      when,
      const NotificationDetails(
        android:
            AndroidNotificationDetails('lesson_reminder', 'Lesson Reminder'),
        iOS: DarwinNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelReminder() async {
    await _init();
    await _plugin.cancel(_id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, false);
  }
}
