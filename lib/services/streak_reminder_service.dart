import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'session_log_service.dart';

class StreakReminderService extends ChangeNotifier {
  static const _enabledKey = 'streak_reminder_enabled';
  static const _id = 130;

  final SessionLogService logs;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _enabled = true;
  Timer? _midnightTimer;
  VoidCallback? _logsListener;

  bool get enabled => _enabled;

  StreakReminderService({required this.logs});

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_enabledKey) ?? true;
    await _initPlugin();
    _logsListener = _schedule;
    logs.addListener(_logsListener!);
    _schedule();
    _scheduleMidnight();
  }

  Future<void> _initPlugin() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin
        .initialize(const InitializationSettings(android: android, iOS: ios));
    tz.initializeTimeZones();
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
    _enabled = value;
    if (!value) await _plugin.cancel(_id);
    _schedule();
    notifyListeners();
  }

  bool _hasTrainedToday() {
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    for (final log in logs.logs) {
      final d = DateTime(
          log.completedAt.year, log.completedAt.month, log.completedAt.day);
      if (d == today) return true;
      if (d.isBefore(today)) break;
    }
    return false;
  }

  Future<void> _schedule() async {
    await _plugin.cancel(_id);
    if (!_enabled) return;
    if (_hasTrainedToday()) return;
    final now = DateTime.now();
    var when = tz.TZDateTime.local(now.year, now.month, now.day, 19);
    if (when.isBefore(tz.TZDateTime.now(tz.local))) {
      when = when.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      _id,
      'Poker Analyzer',
      'Don\u2019t break your streak! Quick session to keep the momentum.',
      when,
      const NotificationDetails(
        android:
            AndroidNotificationDetails('streak_reminder', 'Streak Reminder'),
        iOS: DarwinNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  void _scheduleMidnight() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(next.difference(now), () {
      _schedule();
      _scheduleMidnight();
    });
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    if (_logsListener != null) logs.removeListener(_logsListener!);
    super.dispose();
  }
}
