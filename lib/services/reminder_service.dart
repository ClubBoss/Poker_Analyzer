import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_goal.dart';
import 'user_goal_engine.dart';
import 'spot_of_the_day_service.dart';
import 'streak_service.dart';
import 'notification_service.dart';

class ReminderService extends ChangeNotifier {
  static const _enabledKey = 'reminders_enabled';
  static const _dismissKey = 'reminder_last_dismiss';
  static const _drillDismissKey = 'reminder_drill_dismiss';

  final SpotOfTheDayService spotService;
  final UserGoalEngine goalEngine;
  final StreakService streakService;
  final BuildContext context;

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
    required this.context,
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
            if (e.value is String &&
                DateTime.tryParse(e.value as String) != null)
              e.key: DateTime.parse(e.value as String)
        };
      } catch (_) {
        _dismissDrillUntil = {};
      }
    }
    _cleanupExpiredDismissals();
    spotService.addListener(_schedule);
    goalEngine.addListener(_schedule);
    streakService.addListener(_schedule);
    _schedule();
    _scheduleResetTimer();
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
    _enabled = value;
    if (!value) {
      await NotificationService.cancel(101);
    } else {
      _schedule();
    }
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
      for (final e in _dismissDrillUntil.entries)
        e.key: e.value.toIso8601String()
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
    await NotificationService.cancel(101);
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
    await NotificationService.scheduleDailyReminder(context);
    await NotificationService.scheduleDailyProgress(context);
  }
}
