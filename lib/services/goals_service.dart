import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:convert';
import 'xp_tracker_service.dart';
import '../screens/progress_screen.dart';
import '../models/goal_progress_entry.dart';
import '../models/drill_session_result.dart';
import '../models/saved_hand.dart';
import 'streak_service.dart';
import 'user_action_logger.dart';

class Achievement {
  final String title;
  final IconData icon;
  final int progress;
  final int target;

  const Achievement({
    required this.title,
    required this.icon,
    required this.progress,
    required this.target,
  });

  bool get completed => progress >= target;

  Achievement copyWith({int? progress}) => Achievement(
        title: title,
        icon: icon,
        progress: progress ?? this.progress,
        target: target,
      );
}

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
  }) =>
      Goal(
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
  static const _prefPrefix = 'goal_progress_';
  static const _streakKey = 'error_free_streak';
  static const _handsKey = 'consecutive_hands';
  static const _mistakeStreakKey = 'mistake_review_streak';
  static const _hintShownKey = 'progress_hint_shown';
  static const _dailyIndexKey = 'daily_goal_index';
  static const _dailyDateKey = 'daily_goal_date';
  static const _achievementShownPrefix = 'ach_shown_';
  static const _historyPrefix = 'goal_history_';
  static const _drillResultsKey = 'drill_results';
  static const _dailySpotHistoryKey = 'daily_spot_history';
  static const _sevenDayGoalKey = 'seven_day_goal_unlocked';

  int _errorFreeStreak = 0;
  int _handStreak = 0;
  int _mistakeReviewStreak = 0;
  bool _hintShown = false;
  int? _dailyGoalIndex;
  DateTime? _dailyGoalDate;
  DateTime? _lastIncrementTime;
  int? _lastIncrementGoal;

  /// In-memory list of all achievements.
  late List<Achievement> _achievements;
  late List<bool> _achievementShown;
  late List<List<GoalProgressEntry>> _history;
  List<DrillSessionResult> _drillResults = [];
  List<DateTime> _dailySpotHistory = [];
  bool _hasSevenDayGoalUnlocked = false;
  bool _weeklyStreakCelebrated = false;

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

  List<Achievement> get achievements => List.unmodifiable(_achievements);

  int get errorFreeStreak => _errorFreeStreak;

  bool get anyCompleted => _goals.any((g) => g.progress >= g.target);

  int get mistakeReviewStreak => _mistakeReviewStreak;

  List<DrillSessionResult> get drillResults => List.unmodifiable(_drillResults);
  List<DateTime> get dailySpotHistory => List.unmodifiable(_dailySpotHistory);
  bool get hasSevenDayGoalUnlocked => _hasSevenDayGoalUnlocked;
  bool get weeklyStreakCelebrated => _weeklyStreakCelebrated;

  List<GoalProgressEntry> historyFor(int index) =>
      index >= 0 && index < _history.length
          ? List.unmodifiable(_history[index])
          : const [];

  DateTime? _readDate(SharedPreferences prefs, int index) {
    final ts = prefs.getInt('${_prefPrefix}${index}_date');
    if (ts == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ts);
  }

  DateTime _readCreated(SharedPreferences prefs, int index) {
    final key = '${_prefPrefix}${index}_created';
    final ts = prefs.getInt(key);
    if (ts != null) return DateTime.fromMillisecondsSinceEpoch(ts);
    final now = DateTime.now();
    prefs.setInt(key, now.millisecondsSinceEpoch);
    return now;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _goals = [
      Goal(
        title: 'Разобрать 5 ошибок',
        progress: prefs.getInt('${_prefPrefix}0') ?? 0,
        target: 5,
        createdAt: _readCreated(prefs, 0),
        icon: Icons.bug_report,
        completedAt: _readDate(prefs, 0),
        rule: (h) =>
            h.expectedAction != null &&
            h.gtoAction != null &&
            h.expectedAction!.trim().toLowerCase() !=
                h.gtoAction!.trim().toLowerCase(),
      ),
      Goal(
        title: 'Пройти 3 раздачи без ошибок подряд',
        progress: prefs.getInt('${_prefPrefix}1') ?? 0,
        target: 3,
        createdAt: _readCreated(prefs, 1),
        icon: Icons.play_circle_fill,
        completedAt: _readDate(prefs, 1),
        rule: (h) =>
            h.expectedAction != null &&
            h.gtoAction != null &&
            h.expectedAction!.trim().toLowerCase() !=
                h.gtoAction!.trim().toLowerCase(),
      ),
    ];
    _history = [];
    for (var i = 0; i < _goals.length; i++) {
      final raw = prefs.getStringList('$_historyPrefix$i') ?? [];
      final list = <GoalProgressEntry>[];
      for (final item in raw) {
        try {
          list.add(GoalProgressEntry.fromJson(
              jsonDecode(item) as Map<String, dynamic>));
        } catch (_) {}
      }
      _history.add(list);
    }
    final rawResults = prefs.getStringList(_drillResultsKey) ?? [];
    _drillResults = [];
    for (final item in rawResults) {
      try {
        final data = jsonDecode(item);
        if (data is Map<String, dynamic>) {
          _drillResults.add(
              DrillSessionResult.fromJson(Map<String, dynamic>.from(data)));
        }
      } catch (_) {}
    }
    final spotRaw = prefs.getStringList(_dailySpotHistoryKey) ?? [];
    _dailySpotHistory = [
      for (final s in spotRaw)
        if (DateTime.tryParse(s) != null) DateTime.parse(s)
    ];
    _errorFreeStreak = prefs.getInt(_streakKey) ?? 0;
    _handStreak = prefs.getInt(_handsKey) ?? 0;
    _mistakeReviewStreak = prefs.getInt(_mistakeStreakKey) ?? 0;
    _hintShown = prefs.getBool(_hintShownKey) ?? false;
    _hasSevenDayGoalUnlocked = prefs.getBool(_sevenDayGoalKey) ?? false;
    _dailyGoalIndex = prefs.getInt(_dailyIndexKey);
    final dateStr = prefs.getString(_dailyDateKey);
    _dailyGoalDate = dateStr != null ? DateTime.tryParse(dateStr) : null;
    final completedGoals =
        _goals.where((g) => g.progress >= g.target).length;
    final allGoalsCompleted = completedGoals == _goals.length ? 1 : 0;
    int drillMaster = 0;
    if (_drillResults.length >= 5) {
      final last = _drillResults.reversed.take(5).toList();
      final avg =
          last.map((e) => e.accuracy).reduce((a, b) => a + b) / last.length;
      if (avg >= 0.8) drillMaster = 1;
    }
    _achievements = [
      const Achievement(
        title: 'Разобрать 5 ошибок',
        icon: Icons.bug_report,
        progress: 0,
        target: 5,
      ),
      const Achievement(
        title: '3 дня подряд',
        icon: Icons.local_fire_department,
        progress: 0,
        target: 3,
      ),
      const Achievement(
        title: 'Цель выполнена',
        icon: Icons.flag,
        progress: 0,
        target: 1,
      ),
      Achievement(
        title: 'Без ошибок подряд',
        icon: Icons.flash_on,
        progress: _errorFreeStreak,
        target: 5,
      ),
      Achievement(
        title: '5 целей выполнено',
        icon: Icons.star,
        progress: completedGoals,
        target: 5,
      ),
      Achievement(
        title: '5 ошибок подряд исправлены',
        icon: Icons.build,
        progress: _mistakeReviewStreak > 5 ? 5 : _mistakeReviewStreak,
        target: 5,
      ),
      Achievement(
        title: 'Все цели выполнены',
        icon: Icons.workspace_premium,
        progress: allGoalsCompleted,
        target: 1,
      ),
      Achievement(
        title: '10 раздач без ошибок',
        icon: Icons.flash_on,
        progress: _errorFreeStreak,
        target: 10,
      ),
      const Achievement(
        title: '7 дней подряд',
        icon: Icons.local_fire_department,
        progress: 0,
        target: 7,
      ),
      Achievement(
        title: 'Drill Master',
        icon: Icons.school,
        progress: drillMaster,
        target: 1,
      ),
    ];
    _achievementShown = [
      for (var i = 0; i < _achievements.length; i++)
        prefs.getBool('$_achievementShownPrefix$i') ?? false
    ];
    await ensureDailyGoal();
    notifyListeners();
  }

  Future<void> _saveErrorFreeStreak() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_streakKey, _errorFreeStreak);
  }

  Future<void> _saveHandStreak() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_handsKey, _handStreak);
  }

  Future<void> _saveMistakeReviewStreak() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_mistakeStreakKey, _mistakeReviewStreak);
  }

  Future<void> _saveHintShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hintShownKey, _hintShown);
  }

  Future<void> _saveAchievementShown(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_achievementShownPrefix$index', true);
  }

  Future<void> _saveHistory(int index) async {
    if (index < 0 || index >= _history.length) return;
    final prefs = await SharedPreferences.getInstance();
    final list = [for (final e in _history[index]) jsonEncode(e.toJson())];
    await prefs.setStringList('$_historyPrefix$index', list);
  }

  Future<void> _saveDailyGoal() async {
    final prefs = await SharedPreferences.getInstance();
    if (_dailyGoalIndex != null) {
      await prefs.setInt(_dailyIndexKey, _dailyGoalIndex!);
    } else {
      await prefs.remove(_dailyIndexKey);
    }
    if (_dailyGoalDate != null) {
      await prefs.setString(_dailyDateKey, _dailyGoalDate!.toIso8601String());
    } else {
      await prefs.remove(_dailyDateKey);
    }
  }

  Future<void> _saveDrillResults() async {
    final prefs = await SharedPreferences.getInstance();
    final list = [for (final r in _drillResults) jsonEncode(r.toJson())];
    await prefs.setStringList(_drillResultsKey, list);
  }

  Future<void> _saveSevenDayGoalUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sevenDayGoalKey, _hasSevenDayGoalUnlocked);
  }

  Future<void> setSevenDayGoalUnlocked(bool value) async {
    if (_hasSevenDayGoalUnlocked == value) return;
    _hasSevenDayGoalUnlocked = value;
    await _saveSevenDayGoalUnlocked();
    notifyListeners();
  }

  void markWeeklyStreakCelebrated() {
    _weeklyStreakCelebrated = true;
  }

  void _checkAchievements(BuildContext context) {
    for (var i = 0; i < _achievements.length && i < _achievementShown.length; i++) {
      if (!_achievementShown[i] && _achievements[i].completed) {
        _achievementShown[i] = true;
        _saveAchievementShown(i);
        context.read<XPTrackerService>().addXp(XPTrackerService.achievementXp);
        if (context.mounted) {
          showAchievementUnlockedOverlay(
              context, _achievements[i].icon, _achievements[i].title);
        }
      }
    }
  }

  Future<void> _saveProgress(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_prefPrefix}$index', _goals[index].progress);
    await prefs.setInt(
        '${_prefPrefix}${index}_created',
        _goals[index].createdAt.millisecondsSinceEpoch);
    final dateKey = '${_prefPrefix}${index}_date';
    final date = _goals[index].completedAt;
    if (date != null) {
      await prefs.setInt(dateKey, date.millisecondsSinceEpoch);
    } else {
      await prefs.remove(dateKey);
    }
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
      await _saveDailyGoal();
      notifyListeners();
    }
  }

  bool _refreshCompletedGoalsAchievement() {
    if (_achievements.length < 5) return false;
    bool changed = false;
    final count = _goals.where((g) => g.progress >= g.target).length;
    if (_achievements[4].progress != count) {
      _achievements[4] = _achievements[4].copyWith(progress: count);
      changed = true;
    }
    if (_achievements.length > 6) {
      final all = count == _goals.length ? 1 : 0;
      if (_achievements[6].progress != all) {
        _achievements[6] = _achievements[6].copyWith(progress: all);
        changed = true;
      }
    }
    return changed;
  }

  Future<void> setProgress(int index, int progress, {BuildContext? context}) async {
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
    await _saveProgress(index);
    await _saveHistory(index);
    _refreshCompletedGoalsAchievement();
    notifyListeners();
    if (context != null) _checkAchievements(context);
  }

  Future<void> resetGoal(int index, {BuildContext? context}) async {
    await setProgress(index, 0, context: context);
  }

  /// Increments the progress for the "mistake review" goal.
  Future<void> recordMistakeReviewed(BuildContext context) async {
    const index = 0;
    if (index >= _goals.length) return;
    final goal = _goals[index];
    if (goal.completed) return;
    await setProgress(index, goal.progress + 1, context: context);
    _lastIncrementGoal = index;
    _lastIncrementTime = DateTime.now();
  }

  /// Records a completed hand and shows a progress hint if needed.
  Future<void> recordHandCompleted(BuildContext context) async {
    _handStreak += 1;
    await _saveHandStreak();
    if (_handStreak >= 5 && !_hintShown) {
      _hintShown = true;
      await _saveHintShown();
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

  /// Updates the consecutive mistake review streak and achievement.
  Future<void> updateMistakeReviewStreak(bool mistake,
      {BuildContext? context}) async {
    final previous = _mistakeReviewStreak;
    _mistakeReviewStreak = mistake ? _mistakeReviewStreak + 1 : 0;
    await _saveMistakeReviewStreak();
    if (_achievements.length > 5) {
      final progress = _mistakeReviewStreak > 5 ? 5 : _mistakeReviewStreak;
      _achievements[5] = _achievements[5].copyWith(progress: progress);
    }
    notifyListeners();
    if (context != null) _checkAchievements(context);
    if (previous < 5 && _mistakeReviewStreak >= 5 && context != null &&
        context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Достижение: 5 ошибок подряд исправлены!')));
    }
  }

  /// Updates the "error free" streak and achievement.
  Future<void> updateErrorFreeStreak(bool correct, {BuildContext? context}) async {
    if (context != null) {
      final service = context.read<StreakService>();
      await service.updateErrorFreeStreak(correct);
      _errorFreeStreak = service.errorFreeStreak;
    } else {
      final next = correct ? _errorFreeStreak + 1 : 0;
      if (next == _errorFreeStreak) return;
      _errorFreeStreak = next;
    }
    if (_achievements.length > 3) {
      _achievements[3] = _achievements[3].copyWith(progress: _errorFreeStreak);
    }
    if (_achievements.length > 7) {
      _achievements[7] = _achievements[7].copyWith(progress: _errorFreeStreak);
    }
    await _saveErrorFreeStreak();
    notifyListeners();
    if (context != null) _checkAchievements(context);
  }

  /// Refreshes the progress values for all achievements.
  void updateAchievements({
    BuildContext? context,
    required int correctHands,
    required int streakDays,
    required bool goalCompleted,
  }) {
    bool changed = false;
    final completedGoals =
        _goals.where((g) => g.progress >= g.target).length;
    final values = [
      correctHands,
      streakDays,
      goalCompleted ? 1 : 0,
    ];
    for (var i = 0; i < _achievements.length && i < values.length; i++) {
      final updated = _achievements[i].copyWith(progress: values[i]);
      if (_achievements[i].progress != updated.progress) {
        changed = true;
        _achievements[i] = updated;
      }
    }
    if (_achievements.length > 8 &&
        _achievements[8].progress != streakDays) {
      _achievements[8] = _achievements[8].copyWith(progress: streakDays);
      changed = true;
    }
    if (_achievements.length > 4 &&
        _achievements[4].progress != completedGoals) {
      _achievements[4] = _achievements[4].copyWith(progress: completedGoals);
      changed = true;
    }
    if (_achievements.length > 6) {
      final all = completedGoals == _goals.length ? 1 : 0;
      if (_achievements[6].progress != all) {
        _achievements[6] = _achievements[6].copyWith(progress: all);
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
      if (context != null) _checkAchievements(context);
    }
  }

  void _updateDrillAchievement() {
    if (_achievements.length < 10) return;
    int value = 0;
    if (_drillResults.length >= 5) {
      final last = _drillResults.reversed.take(5).toList();
      final avg = last.map((e) => e.accuracy).reduce((a, b) => a + b) / last.length;
      if (avg >= 0.8) value = 1;
    }
    if (_achievements[9].progress != value) {
      _achievements[9] = _achievements[9].copyWith(progress: value);
    }
  }

  Future<void> saveDrillResult(DrillSessionResult r, {BuildContext? context}) async {
    _drillResults.add(r);
    await _saveDrillResults();
    _updateDrillAchievement();
    notifyListeners();
    if (context != null) _checkAchievements(context);
  }

  Future<SavedHand?> getDailySpot(List<TrainingPack> packs) async {
    final prefs = await SharedPreferences.getInstance();
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
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_dailySpotHistoryKey) ?? [];
    return [
      for (final s in raw)
        if (DateTime.tryParse(s) != null) DateTime.parse(s)
    ];
  }

  Future<bool> hasWeeklyStreak() async {
    final history = await getDailySpotHistory();
    final set = {
      for (final d in history) DateTime(d.year, d.month, d.day)
    };
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: i));
      if (!set.contains(day)) return false;
    }
    return true;
  }
}
