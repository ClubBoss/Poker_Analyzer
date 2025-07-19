import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'daily_challenge_meta_service.dart';

class DailyChallengeNotificationService {
  DailyChallengeNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static const int _id = 111; // Unique notification ID

  static Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
    tz.initializeTimeZones();
    _initialized = true;
  }

  static Future<void> scheduleDailyReminder({TimeOfDay time = const TimeOfDay(hour: 12, minute: 0)}) async {
    await init();
    final state = await DailyChallengeMetaService.instance.getTodayState();
    if (state == ChallengeState.locked) return;
    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (!when.isAfter(now)) {
      when = when.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      _id,
      'Poker Analyzer',
      '🎯 Готов к челленджу дня? Вернись и улучшай свои навыки!',
      when,
      const NotificationDetails(
        android: AndroidNotificationDetails('daily_challenge', 'Daily Challenge'),
        iOS: DarwinNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelDailyReminder() async {
    await init();
    await _plugin.cancel(_id);
  }
}
