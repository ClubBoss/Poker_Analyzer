import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Log entry describing when a short-term XP goal was completed.
class GoalCompletionLog {
  final String goalId;
  final DateTime completedAt;

  GoalCompletionLog({required this.goalId, required this.completedAt});

  Map<String, dynamic> toJson() => {
    'goalId': goalId,
    'completedAt': completedAt.toIso8601String(),
  };

  factory GoalCompletionLog.fromJson(Map<String, dynamic> json) =>
      GoalCompletionLog(
        goalId: json['goalId'] as String? ?? '',
        completedAt:
            DateTime.tryParse(json['completedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// Persists completed XP goals to local storage and provides basic analytics.
class GoalProgressPersistenceService {
  GoalProgressPersistenceService._();
  static final GoalProgressPersistenceService instance =
      GoalProgressPersistenceService._();

  static const _prefsKey = 'xp_goal_completion_logs';

  final List<GoalCompletionLog> _logs = [];
  bool _loaded = false;

  /// Clears cached data for tests.
  void resetForTest() {
    _loaded = false;
    _logs.clear();
  }

  Future<void> _load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final data = jsonDecode(raw) as List;
        _logs
          ..clear()
          ..addAll(
            data.map(
              (e) => GoalCompletionLog.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            ),
          );
      } catch (_) {
        _logs.clear();
      }
    }
    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode([for (final l in _logs) l.toJson()]),
    );
  }

  /// Records that [goalId] was completed at [when].
  Future<void> markCompleted(String goalId, DateTime when) async {
    await _load();
    _logs.add(GoalCompletionLog(goalId: goalId, completedAt: when));
    await _save();
  }

  /// Returns all goal completions logged for today.
  Future<List<GoalCompletionLog>> getTodayGoals() async {
    await _load();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return [
      for (final l in _logs)
        if (!l.completedAt.isBefore(start) && l.completedAt.isBefore(end)) l,
    ];
  }

  /// Returns a copy of all stored goal completion logs sorted by time.
  Future<List<GoalCompletionLog>> getAllLogs() async {
    await _load();
    final list = List<GoalCompletionLog>.from(_logs)
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
    return list;
  }

  /// Returns total XP earned from goal completions during the current week.
  /// [xpPerGoal] allows overriding the XP value granted per goal.
  Future<int> getWeeklyXP({int xpPerGoal = 25}) async {
    await _load();
    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    int count = 0;
    for (final l in _logs) {
      if (!l.completedAt.isBefore(startOfWeek) &&
          l.completedAt.isBefore(endOfWeek)) {
        count++;
      }
    }
    return count * xpPerGoal;
  }

  /// Returns true if [goalId] was completed today.
  Future<bool> isCompletedToday(String goalId) async {
    final todayGoals = await getTodayGoals();
    return todayGoals.any((g) => g.goalId == goalId);
  }
}
