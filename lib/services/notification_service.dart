import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
    tz.initializeTimeZones();
  }

  static Future<void> cancel(int id) => _plugin.cancel(id);

  static Future<void> scheduleDailyReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString('last_training_day');
    final now = DateTime.now();
    var day = DateTime(now.year, now.month, now.day);
    final today = _fmt(day);
    if (last == today) day = day.add(const Duration(days: 1));
    final when = tz.TZDateTime.local(day.year, day.month, day.day, 20);
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
