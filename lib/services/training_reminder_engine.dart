import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'session_log_service.dart';
import 'smart_pack_recommendation_engine.dart' show UserProfile;

class TrainingReminderEngine {
  final SessionLogService logs;

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  TrainingReminderEngine({required this.logs});

  Future<void> _init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin
        .initialize(const InitializationSettings(android: android, iOS: ios));
    tz.initializeTimeZones();
    _initialized = true;
  }

  static const _checkKey = 'lastReminderCheck';

  Future<bool> shouldRemind(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastStr = prefs.getString(_checkKey);
    final lastCheck = lastStr == null ? null : DateTime.tryParse(lastStr);
    if (lastCheck != null &&
        now.difference(lastCheck) < const Duration(days: 1)) {
      return false;
    }
    await prefs.setString(_checkKey, now.toIso8601String());

    await logs.load();
    DateTime? last;
    for (final l in logs.logs) {
      final d = l.completedAt;
      if (last == null || d.isAfter(last)) last = d;
    }
    if (last == null) return true;
    return now.difference(last) > const Duration(days: 3);
  }

  /// Schedule a local notification encouraging training if the user
  /// hasn't trained today. The notification fires at 20:00 local time.
  Future<void> scheduleDailyReminder({
    required DateTime lastTrainingTime,
    required int streakDays,
  }) async {
    await _init();
    final now = tz.TZDateTime.now(tz.local);
    final today = tz.TZDateTime(tz.local, now.year, now.month, now.day);
    final lastDay = tz.TZDateTime(tz.local, lastTrainingTime.year,
        lastTrainingTime.month, lastTrainingTime.day);
    if (lastDay.isAtSameMomentAs(today)) return;

    var when = tz.TZDateTime(tz.local, today.year, today.month, today.day, 20);
    if (!when.isAfter(now)) {
      when = when.add(const Duration(days: 1));
    }

    final body = streakDays >= 3
        ? '🔥 Keep your streak alive! Jump into training.'
        : '🏋️ Ready to improve today? Your next pack awaits.';

    await _plugin.zonedSchedule(
      131,
      'Poker Analyzer',
      body,
      when,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'training_reminder',
          'Training Reminder',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
