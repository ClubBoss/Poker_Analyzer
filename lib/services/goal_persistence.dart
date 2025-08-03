import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/goal_progress_entry.dart';
import '../models/drill_session_result.dart';

/// Encapsulates persistence for goal and achievement related data.
class GoalPersistence {
  static const prefPrefix = 'goal_progress_';
  static const streakKey = 'error_free_streak';
  static const handsKey = 'consecutive_hands';
  static const mistakeStreakKey = 'mistake_review_streak';
  static const hintShownKey = 'progress_hint_shown';
  static const dailyIndexKey = 'daily_goal_index';
  static const dailyDateKey = 'daily_goal_date';
  static const achievementShownPrefix = 'ach_shown_';
  static const historyPrefix = 'goal_history_';
  static const drillResultsKey = 'drill_results';
  static const dailySpotHistoryKey = 'daily_spot_history';
  static const sevenDayGoalKey = 'seven_day_goal_unlocked';
  static const weeklyHandsTargetKey = 'weekly_hands_target';
  static const weeklyAccuracyTargetKey = 'weekly_accuracy_target';

  final SharedPreferences prefs;

  GoalPersistence(this.prefs);

  static Future<GoalPersistence> load() async {
    final prefs = await SharedPreferences.getInstance();
    return GoalPersistence(prefs);
  }

  DateTime? readDate(int index) {
    final ts = prefs.getInt('$prefPrefix${index}_date');
    if (ts == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ts);
  }

  DateTime readCreated(int index) {
    final key = '$prefPrefix${index}_created';
    final ts = prefs.getInt(key);
    if (ts != null) return DateTime.fromMillisecondsSinceEpoch(ts);
    final now = DateTime.now();
    prefs.setInt(key, now.millisecondsSinceEpoch);
    return now;
  }

  Future<List<List<GoalProgressEntry>>> loadHistory(int goalCount) async {
    final result = <List<GoalProgressEntry>>[];
    for (var i = 0; i < goalCount; i++) {
      final raw = prefs.getStringList('$historyPrefix$i') ?? [];
      final list = <GoalProgressEntry>[];
      for (final item in raw) {
        try {
          list.add(
              GoalProgressEntry.fromJson(jsonDecode(item) as Map<String, dynamic>));
        } catch (_) {}
      }
      result.add(list);
    }
    return result;
  }

  Future<List<DrillSessionResult>> loadDrillResults() async {
    final raw = prefs.getStringList(drillResultsKey) ?? [];
    final list = <DrillSessionResult>[];
    for (final item in raw) {
      try {
        final data = jsonDecode(item);
        if (data is Map<String, dynamic>) {
          list.add(DrillSessionResult.fromJson(Map<String, dynamic>.from(data)));
        }
      } catch (_) {}
    }
    return list;
  }

  List<DateTime> loadDailySpotHistory() {
    final spotRaw = prefs.getStringList(dailySpotHistoryKey) ?? [];
    return [
      for (final s in spotRaw)
        if (DateTime.tryParse(s) != null) DateTime.parse(s)
    ];
  }

  Future<GoalPersistenceState> loadState(int goalCount) async {
    final goals = <GoalData>[];
    for (var i = 0; i < goalCount; i++) {
      goals.add(GoalData(
        progress: prefs.getInt('$prefPrefix$i') ?? 0,
        createdAt: readCreated(i),
        completedAt: readDate(i),
      ));
    }
    final history = await loadHistory(goalCount);
    final drillResults = await loadDrillResults();
    final dailySpotHistory = loadDailySpotHistory();
    return GoalPersistenceState(
      goals: goals,
      history: history,
      drillResults: drillResults,
      dailySpotHistory: dailySpotHistory,
      errorFreeStreak: loadErrorFreeStreak(),
      handStreak: loadHandStreak(),
      mistakeReviewStreak: loadMistakeReviewStreak(),
      hintShown: loadHintShown(),
      hasSevenDayGoalUnlocked: loadSevenDayGoalUnlocked(),
      dailyGoalIndex: loadDailyGoalIndex(),
      dailyGoalDate: loadDailyGoalDate(),
      weeklyHandsTarget: loadWeeklyHandsTarget(),
      weeklyAccuracyTarget: loadWeeklyAccuracyTarget(),
    );
  }

  Future<void> saveProgress(int index, int progress, DateTime createdAt,
      DateTime? completedAt) async {
    await prefs.setInt('$prefPrefix$index', progress);
    await prefs.setInt('$prefPrefix${index}_created', createdAt.millisecondsSinceEpoch);
    final dateKey = '$prefPrefix${index}_date';
    if (completedAt != null) {
      await prefs.setInt(dateKey, completedAt.millisecondsSinceEpoch);
    } else {
      await prefs.remove(dateKey);
    }
  }

  Future<void> saveHistory(int index, List<GoalProgressEntry> history) async {
    final list = [for (final e in history) jsonEncode(e.toJson())];
    await prefs.setStringList('$historyPrefix$index', list);
  }

  Future<void> saveErrorFreeStreak(int value) async {
    await prefs.setInt(streakKey, value);
  }

  Future<void> saveHandStreak(int value) async {
    await prefs.setInt(handsKey, value);
  }

  Future<void> saveMistakeReviewStreak(int value) async {
    await prefs.setInt(mistakeStreakKey, value);
  }

  Future<void> saveHintShown(bool value) async {
    await prefs.setBool(hintShownKey, value);
  }

  Future<void> saveAchievementShown(int index) async {
    await prefs.setBool('$achievementShownPrefix$index', true);
  }

  Future<void> saveDailyGoal(int? index, DateTime? date) async {
    if (index != null) {
      await prefs.setInt(dailyIndexKey, index);
    } else {
      await prefs.remove(dailyIndexKey);
    }
    if (date != null) {
      await prefs.setString(dailyDateKey, date.toIso8601String());
    } else {
      await prefs.remove(dailyDateKey);
    }
  }

  Future<void> saveDrillResults(List<DrillSessionResult> results) async {
    final list = [for (final r in results) jsonEncode(r.toJson())];
    await prefs.setStringList(drillResultsKey, list);
  }

  Future<void> saveSevenDayGoalUnlocked(bool value) async {
    await prefs.setBool(sevenDayGoalKey, value);
  }

  Future<void> saveWeeklyHandsTarget(int value) async {
    await prefs.setInt(weeklyHandsTargetKey, value);
  }

  Future<void> saveWeeklyAccuracyTarget(double value) async {
    await prefs.setDouble(weeklyAccuracyTargetKey, value);
  }

  int loadWeeklyHandsTarget() => prefs.getInt(weeklyHandsTargetKey) ?? 100;
  double loadWeeklyAccuracyTarget() =>
      prefs.getDouble(weeklyAccuracyTargetKey) ?? 80.0;

  int loadErrorFreeStreak() => prefs.getInt(streakKey) ?? 0;
  int loadHandStreak() => prefs.getInt(handsKey) ?? 0;
  int loadMistakeReviewStreak() => prefs.getInt(mistakeStreakKey) ?? 0;
  bool loadHintShown() => prefs.getBool(hintShownKey) ?? false;
  bool loadSevenDayGoalUnlocked() => prefs.getBool(sevenDayGoalKey) ?? false;
  int? loadDailyGoalIndex() => prefs.getInt(dailyIndexKey);
  DateTime? loadDailyGoalDate() {
    final dateStr = prefs.getString(dailyDateKey);
    return dateStr != null ? DateTime.tryParse(dateStr) : null;
  }

  Future<List<bool>> loadAchievementShown(int count) async {
    return [
      for (var i = 0; i < count; i++)
        prefs.getBool('$achievementShownPrefix$i') ?? false
    ];
  }
}

class GoalPersistenceState {
  GoalPersistenceState({
    required this.goals,
    required this.history,
    required this.drillResults,
    required this.dailySpotHistory,
    required this.errorFreeStreak,
    required this.handStreak,
    required this.mistakeReviewStreak,
    required this.hintShown,
    required this.hasSevenDayGoalUnlocked,
    required this.dailyGoalIndex,
    required this.dailyGoalDate,
    required this.weeklyHandsTarget,
    required this.weeklyAccuracyTarget,
  });

  final List<GoalData> goals;
  final List<List<GoalProgressEntry>> history;
  final List<DrillSessionResult> drillResults;
  final List<DateTime> dailySpotHistory;
  final int errorFreeStreak;
  final int handStreak;
  final int mistakeReviewStreak;
  final bool hintShown;
  final bool hasSevenDayGoalUnlocked;
  final int? dailyGoalIndex;
  final DateTime? dailyGoalDate;
  final int weeklyHandsTarget;
  final double weeklyAccuracyTarget;
}

class GoalData {
  GoalData({
    required this.progress,
    required this.createdAt,
    required this.completedAt,
  });

  final int progress;
  final DateTime createdAt;
  final DateTime? completedAt;
}
