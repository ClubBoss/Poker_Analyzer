import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'daily_challenge_meta_service.dart';

class DailyChallengeNotificationService {
  DailyChallengeNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static const int _id = 111; // Unique notification ID
  static const String _hourKey = 'daily_challenge_reminder_hour';
  static const String _minuteKey = 'daily_challenge_reminder_minute';

  static Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      InitializationSettings(android: android, iOS: ios),
    );
    tz.initializeTimeZones();
    _initialized = true;
  }

  static Future<TimeOfDay> getScheduledTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_hourKey) ?? 12;
    final minute = prefs.getInt(_minuteKey) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static Future<void> scheduleDailyReminder({TimeOfDay? time}) async {
    await init();
    final t = time ?? await getScheduledTime();
    final state = await DailyChallengeMetaService.instance.getTodayState();
    if (state == ChallengeState.locked) return;
    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      t.hour,
      t.minute,
    );
    if (!when.isAfter(now)) {
      when = when.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      _id,
      'Poker Analyzer',
      '🎯 Готов к челленджу дня? Вернись и улучшай свои навыки!',
      when,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_challenge',
          'Daily Challenge',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelDailyReminder() async {
    await init();
    await _plugin.cancel(_id);
  }
}
