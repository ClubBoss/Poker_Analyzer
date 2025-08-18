import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_goal.dart';
import 'user_goal_engine.dart';
import 'daily_training_reminder_service.dart';
import 'goal_analytics_service.dart';

/// Schedules gentle reminders for stale user goals.
class SmartGoalReminderScheduler with WidgetsBindingObserver {
  SmartGoalReminderScheduler({required this.goals, required this.reminder});

  /// Engine providing the list of user goals.
  final UserGoalEngine goals;

  /// Service used to schedule push notifications.
  final DailyTrainingReminderService reminder;

  Timer? _timer;

  static const String _logKey = 'goal_reminder_log';
  static const Duration _stale = Duration(days: 3);
  static const Duration _repeat = Duration(days: 7);

  /// Begins periodic evaluation of stale goals.
  Future<void> start({Duration interval = const Duration(hours: 12)}) async {
    WidgetsBinding.instance.addObserver(this);
    await _evaluate();
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => _evaluate());
  }

  /// Stops all scheduled work.
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _evaluate();
    }
  }

  Future<void> _evaluate() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, String> log = {};
    final raw = prefs.getString(_logKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final data = jsonDecode(raw) as Map;
        for (final e in data.entries) {
          log[e.key.toString()] = e.value.toString();
        }
      } catch (_) {}
    }

    final hist = await GoalAnalyticsService.instance.getGoalHistory();
    final Map<String, DateTime> last = {};
    for (final e in hist) {
      final id = e['goalId'] as String?;
      if (id == null) continue;
      final tsStr = e['timestamp'] as String? ?? e['time'] as String?;
      final ts = tsStr != null ? DateTime.tryParse(tsStr) : null;
      if (ts == null) continue;
      final prev = last[id];
      if (prev == null || ts.isAfter(prev)) last[id] = ts;
    }

    final now = DateTime.now();
    for (final UserGoal g in goals.goals) {
      if (g.completed) continue;
      final lastUpdate = last[g.id] ?? g.createdAt;
      if (now.difference(lastUpdate) <= _stale) continue;
      final lastRemStr = log[g.id];
      if (lastRemStr != null) {
        final lastRem = DateTime.tryParse(lastRemStr);
        if (lastRem != null && now.difference(lastRem) < _repeat) {
          continue;
        }
      }
      await reminder.scheduleOneTimePush(
        '📝 Цель "${g.title}" ждёт продолжения',
      );
      log[g.id] = now.toIso8601String();
    }

    await prefs.setString(_logKey, jsonEncode(log));
  }
}
