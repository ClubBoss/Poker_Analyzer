import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'tag_mastery_history_service.dart';
import '../screens/library_screen.dart';

class DailyTrainingReminderService {
  static const _lastKey = 'daily_training_reminder_last';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  Future<void> _initPlugin() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      InitializationSettings(android: android, iOS: ios),
    );
    tz.initializeTimeZones();
    _initialized = true;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Schedules a one-time push notification [body] a few minutes from now.
  Future<void> scheduleOneTimePush(
    String body, {
    Duration delay = const Duration(minutes: 1),
  }) async {
    await _initPlugin();
    final when = tz.TZDateTime.now(tz.local).add(delay);
    await _plugin.zonedSchedule(
      240,
      'Poker Analyzer',
      body,
      when,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'goal_reengage',
          'Goal Reengagement',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> maybeShowReminder(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastStr = prefs.getString(_lastKey);
    final last = lastStr == null ? null : DateTime.tryParse(lastStr);
    if (last != null && _sameDay(last, now)) return;
    if (now.hour < 18) return;

    final history = await context.read<TagMasteryHistoryService>().getHistory();
    final today = DateTime(now.year, now.month, now.day);
    var trained = false;
    for (final list in history.values) {
      for (final e in list) {
        final d = DateTime(e.date.year, e.date.month, e.date.day);
        if (d == today && e.xp > 0) {
          trained = true;
          break;
        }
      }
      if (trained) break;
    }
    if (trained) return;

    await prefs.setString(_lastKey, now.toIso8601String());
    if (!context.mounted) return;
    final accent = Theme.of(context).colorScheme.secondary;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.alarm, color: accent, size: 28),
            SizedBox(width: 8),
            Text('⏰ Не забудь потренироваться!'),
          ],
        ),
        content: const Text(
          'Ещё не было активности сегодня. Сделай хотя бы один шаг 💪',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Позже'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LibraryScreen()),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: accent),
            child: const Text('Начать тренировку'),
          ),
        ],
      ),
    );
  }
}
