import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'remote_config_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _timeKey = 'daily_reminder_time';

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
    tz.initializeTimeZones();
  }

  static Future<void> cancel(int id) => _plugin.cancel(id);

  static Future<int> _loadTime(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final def = context
        .read<RemoteConfigService>()
        .get<int>('dailyReminderDefaultMinutes', 20 * 60);
    return prefs.getInt(_timeKey) ?? def;
  }

  static Future<TimeOfDay> getReminderTime(BuildContext context) async {
    final m = await _loadTime(context);
    return TimeOfDay(hour: m ~/ 60, minute: m % 60);
  }

  static Future<void> updateReminderTime(BuildContext context, TimeOfDay t) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_timeKey, t.hour * 60 + t.minute);
    await cancel(101);
    await scheduleDailyReminder(context);
  }

  static Future<void> scheduleDailyReminder(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString('last_training_day');
    final time = await _loadTime(context);
    final now = DateTime.now();
    var day = DateTime(now.year, now.month, now.day);
    final today = _fmt(day);
    if (last == today) day = day.add(const Duration(days: 1));
    final when = tz.TZDateTime.local(
      day.year,
      day.month,
      day.day,
      time ~/ 60,
      time % 60,
    );
    await _plugin.zonedSchedule(
      101,
      'Poker Analyzer',
      'Time to train!',
      when,
      const NotificationDetails(
        android: AndroidNotificationDetails('daily_push', 'Daily Push'),
        iOS: DarwinNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
