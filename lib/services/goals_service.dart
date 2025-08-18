import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'training_stats_service.dart';
import '../screens/progress_screen.dart';
import '../models/goal_progress_entry.dart';
import '../models/drill_session_result.dart';
import '../models/saved_hand.dart';
import '../models/ev_recovery_goal.dart';
import '../models/training_pack.dart';
import 'saved_hand_manager_service.dart';
import 'user_action_logger.dart';
import 'goal_persistence.dart';
import 'achievement_manager.dart';

class Goal {
  final String title;
  final int progress;
  final int target;
  final DateTime createdAt;
  final IconData? icon;
  final DateTime? completedAt;
  final bool Function(SavedHand hand)? rule;

  const Goal({
    required this.title,
    required this.progress,
    required this.target,
    required this.createdAt,
    this.icon,
    this.completedAt,
    this.rule,
  });

  bool get completed => progress >= target;

  bool isViolatedBy(SavedHand hand) => rule?.call(hand) ?? false;

  Goal copyWith({
    int? progress,
    int? target,
    DateTime? createdAt,
    DateTime? completedAt,
    bool Function(SavedHand hand)? rule,
  }) => Goal(
    title: title,
    progress: progress ?? this.progress,
    target: target ?? this.target,
    createdAt: createdAt ?? this.createdAt,
    icon: icon,
    completedAt: completedAt ?? this.completedAt,
    rule: rule ?? this.rule,
  );
}

class GoalsService extends ChangeNotifier {
  late GoalPersistence _persistence;
  late AchievementManager _achievementManager;

  int _errorFreeStreak = 0;
  int _handStreak = 0;
  int _mistakeReviewStreak = 0;
  bool _hintShown = false;
  int? _dailyGoalIndex;
  DateTime? _dailyGoalDate;
  DateTime? _lastIncrementTime;
  int? _lastIncrementGoal;
  late List<List<GoalProgressEntry>> _history;
  List<DrillSessionResult> _drillResults = [];
  List<DateTime> _dailySpotHistory = [];
  bool _hasSevenDayGoalUnlocked = false;
  bool _weeklyStreakCelebrated = false;
  int _weeklyHandsTarget = 100;
  double _weeklyAccuracyTarget = 80.0;

  static GoalsService? _instance;
  static GoalsService? get instance => _instance;

  GoalsService() {
    _instance = this;
  }

  late List<Goal> _goals;

  List<Goal> get goals => List.unmodifiable(_goals);

  Goal? get currentGoal {
    for (final g in _goals) {
      if (!g.completed) return g;
    }
    return null;
  }

  Goal? get dailyGoal =>
      _dailyGoalIndex != null &&
          _dailyGoalIndex! >= 0 &&
          _dailyGoalIndex! < _goals.length
      ? _goals[_dailyGoalIndex!]
      : null;
  int? get dailyGoalIndex => _dailyGoalIndex;

  DateTime? get lastIncrementTime => _lastIncrementTime;
  int? get lastIncrementGoal => _lastIncrementGoal;

  List<Achievement> get achievements => _achievementManager.achievements;

  int get errorFreeStreak => _errorFreeStreak;

  bool get anyCompleted => _goals.any((g) => g.progress >= g.target);

  int get mistakeReviewStreak => _mistakeReviewStreak;

  List<DrillSessionResult> get drillResults => List.unmodifiable(_drillResults);
  List<DateTime> get dailySpotHistory => List.unmodifiable(_dailySpotHistory);
  bool get hasSevenDayGoalUnlocked => _hasSevenDayGoalUnlocked;
  bool get weeklyStreakCelebrated => _weeklyStreakCelebrated;
  int get weeklyHandsTarget => _weeklyHandsTarget;
  double get weeklyAccuracyTarget => _weeklyAccuracyTarget;

  Future<void> load() async {
    _persistence = await GoalPersistence.load();
    final state = await _persistence.loadState(2);
    _weeklyHandsTarget = state.weeklyHandsTarget;
    _weeklyAccuracyTarget = state.weeklyAccuracyTarget;
    _goals = [
      Goal(
        title: 'Разобрать 5 ошибок',
        progress: state.goals[0].progress,
        target: 5,
        createdAt: state.goals[0].createdAt,
        icon: Icons.bug_report,
        completedAt: state.goals[0].completedAt,
        rule: (h) =>
            h.expectedAction != null &&
            h.gtoAction != null &&
            h.expectedAction!.trim().toLowerCase() !=
                h.gtoAction!.trim().toLowerCase(),
      ),
      Goal(
        title: 'Пройти 3 раздачи без ошибок подряд',
        progress: state.goals[1].progress,
        target: 3,
        createdAt: state.goals[1].createdAt,
        icon: Icons.play_circle_fill,
        completedAt: state.goals[1].completedAt,
        rule: (h) =>
            h.expectedAction != null &&
            h.gtoAction != null &&
            h.expectedAction!.trim().toLowerCase() !=
                h.gtoAction!.trim().toLowerCase(),
      ),
    ];
    _history = state.history;
    _drillResults = state.drillResults;
    _dailySpotHistory = state.dailySpotHistory;
    _errorFreeStreak = state.errorFreeStreak;
    _handStreak = state.handStreak;
    _mistakeReviewStreak = state.mistakeReviewStreak;
    _hintShown = state.hintShown;
    _hasSevenDayGoalUnlocked = state.hasSevenDayGoalUnlocked;
    _dailyGoalIndex = state.dailyGoalIndex;
    _dailyGoalDate = state.dailyGoalDate;
    final completedGoals = _goals.where((g) => g.progress >= g.target).length;
    int drillMaster = 0;
    if (_drillResults.length >= 5) {
      final last = _drillResults.reversed.take(5).toList();
      final avg =
          last.map((e) => e.accuracy).reduce((a, b) => a + b) / last.length;
      if (avg >= 0.8) drillMaster = 1;
    }
    final allGoalsCompleted = completedGoals == _goals.length;
    _achievementManager = AchievementManager(_persistence);
    await _achievementManager.init(
      errorFreeStreak: _errorFreeStreak,
      mistakeReviewStreak: _mistakeReviewStreak,
      completedGoals: completedGoals,
      allGoalsCompleted: allGoalsCompleted,
      drillMaster: drillMaster,
    );
    await ensureDailyGoal();
    notifyListeners();
  }

  Future<void> setSevenDayGoalUnlocked(bool value) async {
    if (_hasSevenDayGoalUnlocked == value) return;
    _hasSevenDayGoalUnlocked = value;
    await _persistence.saveSevenDayGoalUnlocked(value);
    notifyListeners();
  }

  Future<void> setWeeklyHandsTarget(int value) async {
    if (_weeklyHandsTarget == value) return;
    _weeklyHandsTarget = value;
    await _persistence.saveWeeklyHandsTarget(value);
    notifyListeners();
  }

  Future<void> setWeeklyAccuracyTarget(double value) async {
    if (_weeklyAccuracyTarget == value) return;
    _weeklyAccuracyTarget = value;
    await _persistence.saveWeeklyAccuracyTarget(value);
    notifyListeners();
  }

  void markWeeklyStreakCelebrated() {
    _weeklyStreakCelebrated = true;
  }

  Future<void> ensureDailyGoal() async {
    final now = DateTime.now();
    if (_dailyGoalDate == null || !_isSameDay(_dailyGoalDate!, now)) {
      final active = <int>[];
      for (var i = 0; i < _goals.length; i++) {
        if (!_goals[i].completed) active.add(i);
      }
      if (active.isNotEmpty) {
        _dailyGoalIndex = active[Random().nextInt(active.length)];
      } else {
        _dailyGoalIndex = null;
      }
      _dailyGoalDate = now;
      await _persistence.saveDailyGoal(_dailyGoalIndex, _dailyGoalDate);
      notifyListeners();
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> setProgress(
    int index,
    int progress, {
    BuildContext? context,
  }) async {
    if (index < 0 || index >= _goals.length) return;
    final goal = _goals[index];
    final time = DateTime.now();
    DateTime? date = goal.completedAt;
    final wasCompleted = goal.progress >= goal.target;
    final willComplete = progress >= goal.target;
    if (!wasCompleted && willComplete) {
      date = time;
      UserActionLogger.instance.log('completed_goal:${goal.title}');
    } else if (!willComplete) {
      date = null;
    }
    _goals[index] = goal.copyWith(progress: progress, completedAt: date);
    if (_history.length <= index) {
      _history.add([]);
    }
    _history[index].add(GoalProgressEntry(date: time, progress: progress));
    await _persistence.saveProgress(
      index,
      _goals[index].progress,
      _goals[index].createdAt,
      date,
    );
    await _persistence.saveHistory(index, _history[index]);
    _achievementManager.refreshCompletedGoalsAchievement(
      _goals.where((g) => g.progress >= g.target).length,
      _goals.length,
    );
    notifyListeners();
    if (context != null) _achievementManager.checkAchievements(context);
  }

  Future<void> resetGoal(int index, {BuildContext? context}) async {
    await setProgress(index, 0, context: context);
  }

  Future<void> recordMistakeReviewed(BuildContext context) async {
    const index = 0;
    if (index >= _goals.length) return;
    final goal = _goals[index];
    if (goal.completed) return;
    await setProgress(index, goal.progress + 1, context: context);
    _lastIncrementGoal = index;
    _lastIncrementTime = DateTime.now();
  }

  Future<void> recordHandCompleted(BuildContext context) async {
    _handStreak += 1;
    await _persistence.saveHandStreak(_handStreak);
    if (_handStreak >= 5 && !_hintShown) {
      _hintShown = true;
      await _persistence.saveHintShown(true);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Вы завершили 5 раздач подряд!'),
            action: SnackBarAction(
              label: 'Посмотреть прогресс',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProgressScreen()),
                );
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> updateMistakeReviewStreak(
    bool mistake, {
    BuildContext? context,
  }) async {
    if (mistake) {
      _mistakeReviewStreak += 1;
    } else {
      _mistakeReviewStreak = 0;
    }
    await _persistence.saveMistakeReviewStreak(_mistakeReviewStreak);
    _achievementManager.updateMistakeReviewStreakAchievement(
      _mistakeReviewStreak,
    );
    notifyListeners();
    if (context != null) _achievementManager.checkAchievements(context);
  }

  Future<void> updateErrorFreeStreak(
    bool mistake, {
    BuildContext? context,
  }) async {
    if (mistake) {
      _errorFreeStreak = 0;
    } else {
      _errorFreeStreak += 1;
    }
    await _persistence.saveErrorFreeStreak(_errorFreeStreak);
    _achievementManager.updateErrorFreeStreakAchievement(_errorFreeStreak);
    notifyListeners();
    if (context != null) _achievementManager.checkAchievements(context);
  }

  void updateAchievements({
    BuildContext? context,
    required int correctHands,
    required int streakDays,
    required bool goalCompleted,
  }) {
    final changed = _achievementManager.updateAchievements(
      context: context,
      correctHands: correctHands,
      streakDays: streakDays,
      goalCompleted: goalCompleted,
      completedGoals: _goals.where((g) => g.progress >= g.target).length,
      totalGoals: _goals.length,
    );
    if (changed) notifyListeners();
  }

  Future<void> saveDrillResult(
    DrillSessionResult r, {
    BuildContext? context,
  }) async {
    _drillResults.add(r);
    await _persistence.saveDrillResults(_drillResults);
    _achievementManager.updateDrillAchievement(_drillResults);
    notifyListeners();
    if (context != null) _achievementManager.checkAchievements(context);
  }

  Future<SavedHand?> getDailySpot(List<TrainingPack> packs) async {
    final prefs = _persistence.prefs;
    final dateStr = prefs.getString('daily_spot_date');
    final now = DateTime.now();
    if (dateStr != null) {
      final date = DateTime.tryParse(dateStr);
      if (date != null && _isSameDay(date, now)) return null;
    }
    final seen = <String>{};
    for (final r in _drillResults) {
      if (_isSameDay(r.date, now)) {
        for (final h in r.hands) {
          seen.add(jsonEncode(h.toJson()));
        }
      }
    }
    final candidates = <SavedHand>[];
    for (final p in packs) {
      for (final h in p.hands) {
        final key = jsonEncode(h.toJson());
        if (!seen.contains(key)) candidates.add(h);
      }
    }
    if (candidates.isEmpty) {
      for (final p in packs) {
        candidates.addAll(p.hands);
      }
    }
    if (candidates.isEmpty) return null;
    final rnd = Random().nextInt(candidates.length);
    return candidates[rnd];
  }

  Future<List<DateTime>> getDailySpotHistory() async {
    return _persistence.loadDailySpotHistory();
  }

  Future<bool> hasWeeklyStreak() async {
    final history = await getDailySpotHistory();
    final set = {for (final d in history) DateTime(d.year, d.month, d.day)};
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      if (!set.contains(day)) return false;
    }
    return true;
  }

  int weeklyHandsProgress() {
    final stats = TrainingStatsService.instance;
    if (stats == null) return 0;
    final list = stats.handsWeekly(2);
    return list.isNotEmpty ? list.last.value : 0;
  }

  int weeklyHandsPrevious() {
    final stats = TrainingStatsService.instance;
    if (stats == null) return 0;
    final list = stats.handsWeekly(2);
    return list.length >= 2 ? list[list.length - 2].value : 0;
  }

  double weeklyAccuracyProgress() {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 7));
    final list = [
      for (final r in _drillResults)
        if (!r.date.isBefore(start) && r.date.isBefore(end)) r,
    ];
    if (list.isEmpty) return 0;
    final sum = list.map((e) => e.accuracy).reduce((a, b) => a + b);
    return sum / list.length * 100;
  }

  double weeklyAccuracyPrevious() {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final prevStart = start.subtract(const Duration(days: 7));
    final list = [
      for (final r in _drillResults)
        if (!r.date.isBefore(prevStart) && r.date.isBefore(start)) r,
    ];
    if (list.isEmpty) return 0;
    final sum = list.map((e) => e.accuracy).reduce((a, b) => a + b);
    return sum / list.length * 100;
  }

  EvRecoveryGoal? get weeklyEvRecoveryGoal {
    final stats = TrainingStatsService.instance;
    final hands = SavedHandManagerService.instance?.hands;
    if (stats == null || hands == null) return null;
    final list = stats.evWeekly(hands, 2);
    if (list.length < 2) return null;
    final prev = list[list.length - 2].value;
    final curr = list.last.value;
    final target = prev < 0 ? -prev : 0.0;
    final progress = curr < 0 ? -curr : 0.0;
    return EvRecoveryGoal(
      type: 'recovery',
      target: target,
      progress: progress,
      completed: progress < target,
    );
  }
}
