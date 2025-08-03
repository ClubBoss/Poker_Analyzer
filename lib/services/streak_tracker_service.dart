import 'package:flutter/material.dart';
import 'package:poker_analyzer/services/preferences_service.dart';

import '../widgets/streak_lost_dialog.dart';
import '../widgets/streak_saved_dialog.dart';
import 'streak_milestone_queue_service.dart';
import 'achievements_engine.dart';
import 'dart:async';

class StreakTrackerService {
  StreakTrackerService._();
  static final StreakTrackerService instance = StreakTrackerService._();

  static const String _lastKey = 'lastActiveDate';
  static const String _currentKey = 'currentStreak';
  static const String _bestKey = 'bestStreak';
  static const String _daysKey = 'streakActiveDays';
  static const String _breakKey = 'streakBreakNotified';
  static const String _freezesKey = 'usedFreezes';
  static const List<int> milestones = [3, 7, 14, 30, 60, 100];

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<bool> markActiveToday(BuildContext context) async {
    final prefs = await PreferencesService.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastStr = prefs.getString(_lastKey);
    final last = lastStr != null ? DateTime.tryParse(lastStr) : null;
    var current = prefs.getInt(_currentKey) ?? 0;
    var best = prefs.getInt(_bestKey) ?? current;
    final list = prefs.getStringList(_daysKey) ?? <String>[];
    final todayStr = today.toIso8601String().split('T').first;
    final set = list.toSet();
    set.add(todayStr);

    if (last != null) {
      final lastDay = DateTime(last.year, last.month, last.day);
      final diff = today.difference(lastDay).inDays;
      if (diff == 1) {
        current += 1;
      } else if (diff > 1) {
        current = 1;
      }
    } else {
      current = 1;
    }

    if (current > best) best = current;

    await prefs.setString(_lastKey, today.toIso8601String());
    await prefs.setInt(_currentKey, current);
    await prefs.setInt(_bestKey, best);
    await prefs.setStringList(_daysKey, set.toList());

    final milestone = milestones.contains(current);
    if (milestone && context.mounted) {
      StreakMilestoneQueueService.instance.addMilestoneToQueue(current);
    }
    unawaited(AchievementsEngine.instance.checkAll());
    return milestone;
  }

  Future<int> getCurrentStreak() async {
    final prefs = await PreferencesService.getInstance();
    final lastStr = prefs.getString(_lastKey);
    final last = lastStr != null ? DateTime.tryParse(lastStr) : null;
    var current = prefs.getInt(_currentKey) ?? 0;
    if (last != null) {
      final lastDay = DateTime(last.year, last.month, last.day);
      final diff = DateTime.now().difference(lastDay).inDays;
      if (diff > 1) {
        current = 0;
        await prefs.setInt(_currentKey, 0);
      }
    } else if (current != 0) {
      current = 0;
      await prefs.setInt(_currentKey, 0);
    }
    return current;
  }

  Future<int> getBestStreak() async {
    final prefs = await PreferencesService.getInstance();
    return prefs.getInt(_bestKey) ?? 0;
  }

  Future<Map<DateTime, bool>> getLast30DaysMap() async {
    final prefs = await PreferencesService.getInstance();
    final list = prefs.getStringList(_daysKey) ?? <String>[];
    final set = list
        .map((e) => DateTime.tryParse(e))
        .whereType<DateTime>()
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 29));
    final map = <DateTime, bool>{};
    for (var i = 0; i < 30; i++) {
      final d = start.add(Duration(days: i));
      map[d] = set.contains(d);
    }
    return map;
  }

  Future<void> checkAndHandleStreakBreak(BuildContext context) async {
    final prefs = await PreferencesService.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastStr = prefs.getString(_lastKey);
    final last = lastStr != null ? DateTime.tryParse(lastStr) : null;
    final breakStr = prefs.getString(_breakKey);
    final lastBreak = breakStr != null ? DateTime.tryParse(breakStr) : null;
    final prevStreak = prefs.getInt(_currentKey) ?? 0;

    if (last == null) return;
    final lastDay = DateTime(last.year, last.month, last.day);
    final diff = today.difference(lastDay).inDays;
    final todayActive = _sameDay(today, lastDay);

    await getCurrentStreak();

    if (diff > 1 && prevStreak > 0 && !todayActive) {
      final notifiedToday = lastBreak != null && _sameDay(today, lastBreak);
      final monthKey =
          '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}';
      final freezes = prefs.getStringList(_freezesKey) ?? <String>[];
      final freezeAvailable = diff == 2 && !freezes.contains(monthKey);
      if (!notifiedToday && context.mounted) {
        if (freezeAvailable) {
          freezes.add(monthKey);
          await prefs.setStringList(_freezesKey, freezes);
          final yesterday = today.subtract(const Duration(days: 1));
          await prefs.setString(_lastKey, yesterday.toIso8601String());
          await showDialog(
            context: context,
            builder: (_) => const StreakSavedDialog(),
          );
        } else {
          await showDialog(
            context: context,
            builder: (_) => StreakLostDialog(previous: prevStreak),
          );
          await prefs.setString(_breakKey, today.toIso8601String());
        }
      }
    }
  }
}
