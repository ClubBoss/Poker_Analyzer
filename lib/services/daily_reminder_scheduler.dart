import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class DailyReminderScheduler {
  static final DailyReminderScheduler instance = DailyReminderScheduler._();
  DailyReminderScheduler._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _packKey = 'daily_reminder_pack';
  static const _countKey = 'daily_reminder_count';
  static const _idBase = 105;

  Future<void> _init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    tz.initializeTimeZones();
    _initialized = true;
  }

  Future<void> scheduleDailyReminder({required String packName}) async {
    await _init();
    final prefs = await SharedPreferences.getInstance();
    final storedPack = prefs.getString(_packKey);
    var count = prefs.getInt(_countKey) ?? 0;
    if (storedPack != packName) {
      await cancelAll();
      count = 0;
      await prefs.setString(_packKey, packName);
    }
    if (count >= 3) return;

    final now = tz.TZDateTime.now(tz.local);
    var first = tz.TZDateTime(local, now.year, now.month, now.day, 18);
    if (!first.isAfter(now)) first = first.add(const Duration(days: 1));

    final body =
        '🔁 Напоминание: вы ещё не начали "[$packName]" - давайте улучшим этот спот!';

    for (int i = count; i < 3; i++) {
      final when = first.add(Duration(days: i));
      await _plugin.zonedSchedule(
        _idBase + i,
        'Poker Analyzer',
        body,
        when,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_pack_reminder',
            'Daily Pack Reminder',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
    await prefs.setInt(_countKey, 3);
  }

  Future<void> cancelAll() async {
    await _init();
    for (int i = 0; i < 3; i++) {
      await _plugin.cancel(_idBase + i);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_packKey);
    await prefs.remove(_countKey);
  }
}
