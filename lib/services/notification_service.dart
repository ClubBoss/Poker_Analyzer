import 'dart:async';
import 'package:poker_analyzer/services/preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'remote_config_service.dart';
import 'training_stats_service.dart';
import 'personal_recommendation_service.dart';
import 'adaptive_training_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../screens/training_home_screen.dart';
import '../main.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _timeKey = 'daily_reminder_time';
  static const _progressId = 102;
  static Timer? _packTimer;

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (r) {
        if (r.payload == 'progress') {
          final ctx = navigatorKey.currentState?.context;
          if (ctx != null) {
            Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const TrainingHomeScreen()),
            );
          }
        }
      },
    );
    tz.initializeTimeZones();
  }

  static Future<void> cancel(int id) => _plugin.cancel(id);

  static Future<int> _loadTime(BuildContext context) async {
    final prefs = await PreferencesService.getInstance();
    final def = context
        .read<RemoteConfigService>()
        .get<int>('dailyReminderDefaultMinutes', 20 * 60);
    return prefs.getInt(_timeKey) ?? def;
  }

  static Future<TimeOfDay> getReminderTime(BuildContext context) async {
    final m = await _loadTime(context);
    return TimeOfDay(hour: m ~/ 60, minute: m % 60);
  }

  static Future<void> updateReminderTime(
      BuildContext context, TimeOfDay t) async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setInt(_timeKey, t.hour * 60 + t.minute);
    await cancel(101);
    await scheduleDailyReminder(context);
  }

  static Future<void> scheduleDailyReminder(BuildContext context) async {
    final prefs = await PreferencesService.getInstance();
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
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> scheduleDailyProgress(BuildContext context) async {
    final stats = context.read<TrainingStatsService>();
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final sessions = stats.sessionsDaily(1);
    if (sessions.isNotEmpty && sessions.first.value > 0) return;
    final rec = context.read<PersonalRecommendationService>();
    final tpl = rec.packs.isNotEmpty ? rec.packs.first : null;
    final prefs = await PreferencesService.getInstance();
    final focus = tpl?.heroPos.label ?? 'training';
    var remaining = 0;
    if (tpl != null) {
      final idx = prefs.getInt('tpl_prog_${tpl.id}') ?? 0;
      remaining = tpl.spots.length - idx - 1;
      if (remaining < 0) remaining = 0;
    }
    var when = tz.TZDateTime.local(today.year, today.month, today.day, 18);
    if (when.isBefore(tz.TZDateTime.now(tz.local))) {
      when = when.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      _progressId,
      'Poker Analyzer',
      '⚡ Готов улучшить $focus? У тебя есть $remaining незавершённых спотов — продолжим тренировку?',
      when,
      const NotificationDetails(
        android: AndroidNotificationDetails('daily_progress', 'Daily Progress'),
        iOS: DarwinNotificationDetails(),
      ),
      payload: 'progress',
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedules a simple notification [body] at the given [when].
  static Future<void> schedule({
    required int id,
    required DateTime when,
    required String body,
    String title = 'Poker Analyzer',
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails('generic', 'Generic'),
        iOS: DarwinNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static void startRecommendedPackTask(BuildContext context) {
    _packTimer?.cancel();
    _packTimer = Timer.periodic(const Duration(hours: 6), (_) async {
      final tpl =
          await context.read<AdaptiveTrainingService>().nextRecommendedPack();
      if (tpl == null) return;
      final prefs = await PreferencesService.getInstance();
      final idx = prefs.getInt('tpl_prog_${tpl.id}') ?? 0;
      final remaining = tpl.spots.length - idx;
      await _plugin.show(
        103,
        'Poker Analyzer',
        '🔥 ${tpl.name} — осталось $remaining спотов',
        const NotificationDetails(
          android: AndroidNotificationDetails('rec_pack', 'Recommended Pack'),
          iOS: DarwinNotificationDetails(),
        ),
      );
    });
  }

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
