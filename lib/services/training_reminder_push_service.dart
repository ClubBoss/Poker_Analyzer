import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:poker_analyzer/services/preferences_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'app_settings_service.dart';
import 'goal_reengagement_service.dart';
import 'training_session_service.dart';

/// Schedules reminder pushes for stale training goals.
class TrainingReminderPushService {
  TrainingReminderPushService._();
  static final TrainingReminderPushService instance =
      TrainingReminderPushService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _lastKey = 'training_goal_push_last';
  static const _id = 308;

  Future<void> _init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
    tz.initializeTimeZones();
    _initialized = true;
  }

  /// Cancels any scheduled reminder.
  Future<void> cancelAll() async {
    await _init();
    await _plugin.cancel(_id);
  }

  /// Reschedules the next reminder push if conditions allow.
  Future<void> reschedule({
    required GoalReengagementService reengagement,
    required TrainingSessionService sessions,
  }) async {
    await _init();
    await AppSettingsService.instance.load();
    if (!AppSettingsService.instance.notificationsEnabled) return;

    await _plugin.cancel(_id);

    if (sessions.currentSession != null && !sessions.isCompleted) return;

    final goal = await reengagement.pickReengagementGoal();
    final tag = goal?.tag?.trim().toLowerCase();
    if (tag == null || tag.isEmpty) return;

    final prefs = await PreferencesService.getInstance();
    final lastStr = prefs.getString(_lastKey);
    if (lastStr != null) {
      final last = DateTime.tryParse(lastStr);
      if (last != null && DateTime.now().difference(last).inHours < 24) {
        return;
      }
    }

    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(tz.local, now.year, now.month, now.day, 11);
    if (!when.isAfter(now)) {
      when = when.add(const Duration(days: 1));
    }

    final body = '⏱️ Продолжите цель: $tag';
    await _plugin.zonedSchedule(
      _id,
      'Poker Analyzer',
      body,
      when,
      const NotificationDetails(
        android: AndroidNotificationDetails('training_goal_reminder', 'Training Goal Reminder'),
        iOS: DarwinNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    await prefs.setString(_lastKey, DateTime.now().toIso8601String());
  }
}

