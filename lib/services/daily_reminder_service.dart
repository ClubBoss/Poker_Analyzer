import 'dart:async';
import 'package:poker_analyzer/services/preferences_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'spot_of_the_day_service.dart';
import 'daily_target_service.dart';
import 'training_stats_service.dart';
import 'daily_goals_service.dart';

class DailyReminderService extends ChangeNotifier {
  static const _enabledKey = 'daily_reminder_enabled';
  static const _hourKey = 'daily_reminder_hour';
  static const _id = 7;

  final SpotOfTheDayService spot;
  final DailyTargetService target;
  final TrainingStatsService stats;
  final DailyGoalsService goals;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  bool _enabled = true;
  int _hour = 20;
  Timer? _timer;
  StreamSubscription<int>? _handsSub;

  bool get enabled => _enabled;
  int get hour => _hour;

  DailyReminderService({
    required this.spot,
    required this.target,
    required this.stats,
    required this.goals,
  });

  Future<void> load() async {
    final prefs = await PreferencesService.getInstance();
    _enabled = prefs.getBool(_enabledKey) ?? true;
    _hour = prefs.getInt(_hourKey) ?? 20;
    await _initPlugin();
    spot.addListener(_schedule);
    goals.addListener(_schedule);
    _handsSub = stats.handsStream.listen((_) => _schedule());
    _schedule();
    _scheduleMidnight();
  }

  Future<void> _initPlugin() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
    tz.initializeTimeZones();
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    final prefs = await PreferencesService.getInstance();
    await prefs.setBool(_enabledKey, value);
    _enabled = value;
    if (!value) await _plugin.cancel(_id);
    _schedule();
    notifyListeners();
  }

  Future<void> setHour(int value) async {
    if (_hour == value) return;
    final prefs = await PreferencesService.getInstance();
    await prefs.setInt(_hourKey, value);
    _hour = value;
    _schedule();
    notifyListeners();
  }

  void _scheduleMidnight() {
    _timer?.cancel();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    _timer = Timer(next.difference(now), () {
      _schedule();
      _scheduleMidnight();
    });
  }

  int get _progress {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return stats.handsPerDay[today] ?? 0;
  }

  Future<void> _schedule() async {
    await _plugin.cancel(_id);
    if (!_enabled) return;
    final needSpot = spot.result == null;
    final needTarget = _progress < target.target;
    final needGoals = goals.anyIncomplete;
    if (!needSpot && !needTarget && !needGoals) return;
    final now = DateTime.now();
    final when = tz.TZDateTime.local(now.year, now.month, now.day, _hour);
    if (when.isBefore(tz.TZDateTime.now(tz.local))) return;
    await _plugin.zonedSchedule(
      _id,
      'Poker Analyzer',
      needSpot
          ? "Don't forget today's Spot!"
          : 'Finish your daily goals!',
      when,
      const NotificationDetails(
        android: AndroidNotificationDetails('daily_reminder', 'Daily Reminder', importance: Importance.defaultImportance),
        iOS: DarwinNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _handsSub?.cancel();
    spot.removeListener(_schedule);
    goals.removeListener(_schedule);
    super.dispose();
  }
}
