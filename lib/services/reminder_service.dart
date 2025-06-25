import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/user_goal.dart';
import 'goal_engine.dart';
import 'spot_of_the_day_service.dart';
import 'streak_service.dart';

class ReminderService extends ChangeNotifier {
  static const _enabledKey = 'reminders_enabled';
  static const _dismissKey = 'reminder_last_dismiss';
  static const _drillDismissKey = 'reminder_drill_dismiss';
  static const _channelId = 'reminders';

  final SpotOfTheDayService spotService;
  final GoalEngine goalEngine;
  final StreakService streakService;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _enabled = true;
  DateTime? _dismissed;
  Map<String, DateTime> _dismissDrillUntil = {};
  Timer? _resetTimer;

  bool get enabled => _enabled;
  DateTime? get lastDismissed => _dismissed;
  bool isDrillDismissed(String key) {
    final until = _dismissDrillUntil[key];
    if (until == null) return false;
    if (until.isBefore(DateTime.now())) {
      _dismissDrillUntil.remove(key);
      _saveDismissals();
      return false;
    }
    return true;
  }

  ReminderService({
    required this.spotService,
    required this.goalEngine,
    required this.streakService,
  });

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_enabledKey) ?? true;
    final str = prefs.getString(_dismissKey);
    _dismissed = str != null ? DateTime.tryParse(str) : null;
    final raw = prefs.getString(_drillDismissKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _dismissDrillUntil = {
          for (final e in data.entries)
            if (e.value is String && DateTime.tryParse(e.value as String) != null)
              e.key: DateTime.parse(e.value as String)
        };
      } catch (_) {
        _dismissDrillUntil = {};
      }
    }
    _cleanupExpiredDismissals();
    await _initPlugin();
    spotService.addListener(_schedule);
    goalEngine.addListener(_schedule);
    streakService.addListener(_schedule);
    _schedule();
    _scheduleResetTimer();
  }

  Future<void> _initPlugin() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (r) {
        if (r.notificationResponseType ==
            NotificationResponseType.dismissed) {
          _onDismiss();
        }
      },
    );
    tz.initializeTimeZones();
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
    _enabled = value;
    if (!value) {
      await _plugin.cancelAll();
    } else {
      _schedule();
    }
    notifyListeners();
  }

  Future<void> _onDismiss() async {
    final prefs = await SharedPreferences.getInstance();
    _dismissed = DateTime.now();
    await prefs.setString(_dismissKey, _dismissed!.toIso8601String());
    notifyListeners();
  }

  bool _cleanupExpiredDismissals() {
    final now = DateTime.now();
    final keys = _dismissDrillUntil.keys.toList();
    var changed = false;
    for (final k in keys) {
      final until = _dismissDrillUntil[k];
      if (until != null && until.isBefore(now)) {
        _dismissDrillUntil.remove(k);
        changed = true;
      }
    }
    return changed;
  }

  Future<void> _saveDismissals() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      for (final e in _dismissDrillUntil.entries) e.key: e.value.toIso8601String()
    };
    await prefs.setString(_drillDismissKey, jsonEncode(data));
  }

  void _scheduleResetTimer() {
    _resetTimer?.cancel();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    _resetTimer = Timer(next.difference(now), () {
      _resetTimer = null;
      if (_cleanupExpiredDismissals()) {
        _saveDismissals();
        notifyListeners();
      }
      _scheduleResetTimer();
    });
  }

  Future<void> dismissDrillForToday(String key) async {
    final now = DateTime.now();
    _dismissDrillUntil[key] = DateTime(now.year, now.month, now.day + 1);
    await _saveDismissals();
    notifyListeners();
    _scheduleResetTimer();
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    spotService.removeListener(_schedule);
    goalEngine.removeListener(_schedule);
    streakService.removeListener(_schedule);
    super.dispose();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _schedule() async {
    await _plugin.cancelAll();
    if (!_enabled) return;
    final now = DateTime.now();
    if (_dismissed != null && _sameDay(_dismissed!, now)) return;
    final needSpot = spotService.result == null;
    UserGoal? activeGoal;
    for (final g in goalEngine.goals) {
      if (!g.completed) {
        activeGoal = g;
        break;
      }
    }
    if (!needSpot && activeGoal == null) return;
    final streak = streakService.count;
    var body = '';
    if (streak > 1) {
      body = 'Maintain your ${streak}-day streak!';
    }
    if (activeGoal != null) {
      if (body.isNotEmpty) body += '\n';
      body += "Don't forget your goal: ${activeGoal.title}";
    } else if (needSpot) {
      if (body.isNotEmpty) body += '\n';
      body += "Complete today's Spot of the Day!";
    }
    var when = tz.TZDateTime.local(now.year, now.month, now.day, 10);
    if (when.isBefore(tz.TZDateTime.now(tz.local))) {
      when = when.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      1,
      'Poker Analyzer',
      body,
      when,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Reminders',
          importance: Importance.defaultImportance,
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

