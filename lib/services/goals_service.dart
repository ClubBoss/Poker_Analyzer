import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../screens/progress_screen.dart';

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

  const Goal({
    required this.title,
    required this.progress,
    required this.target,
    required this.createdAt,
    this.icon,
    this.completedAt,
  });

  bool get completed => progress >= target;

  Goal copyWith({
    int? progress,
    int? target,
    DateTime? createdAt,
    DateTime? completedAt,
  }) =>
      Goal(
        title: title,
        progress: progress ?? this.progress,
        target: target ?? this.target,
        createdAt: createdAt ?? this.createdAt,
        icon: icon,
        completedAt: completedAt ?? this.completedAt,
      );
}

class GoalsService extends ChangeNotifier {
  static const _prefPrefix = 'goal_progress_';
  static const _streakKey = 'error_free_streak';
  static const _handsKey = 'consecutive_hands';
  static const _hintShownKey = 'progress_hint_shown';
  static const _dailyIndexKey = 'daily_goal_index';
  static const _dailyDateKey = 'daily_goal_date';

  int _errorFreeStreak = 0;
  int _handStreak = 0;
  bool _hintShown = false;
  int? _dailyGoalIndex;
  DateTime? _dailyGoalDate;
  DateTime? _lastIncrementTime;
  int? _lastIncrementGoal;

  /// In-memory list of all achievements.
  late List<Achievement> _achievements;

  static GoalsService? _instance;
  static GoalsService? get instance => _instance;

  GoalsService() {
    _instance = this;
  }

  late List<Goal> _goals;

  List<Goal> get goals => List.unmodifiable(_goals);

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
      ),
      Goal(
        title: 'Пройти 3 раздачи без ошибок подряд',
        progress: prefs.getInt('${_prefPrefix}1') ?? 0,
        target: 3,
        createdAt: _readCreated(prefs, 1),
        icon: Icons.play_circle_fill,
        completedAt: _readDate(prefs, 1),
      ),
    ];
    _errorFreeStreak = prefs.getInt(_streakKey) ?? 0;
    _handStreak = prefs.getInt(_handsKey) ?? 0;
    _hintShown = prefs.getBool(_hintShownKey) ?? false;
    _dailyGoalIndex = prefs.getInt(_dailyIndexKey);
    final dateStr = prefs.getString(_dailyDateKey);
    _dailyGoalDate = dateStr != null ? DateTime.tryParse(dateStr) : null;
    final completedGoals =
        _goals.where((g) => g.progress >= g.target).length;
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

  Future<void> _saveHintShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hintShownKey, _hintShown);
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
    final count = _goals.where((g) => g.progress >= g.target).length;
    if (_achievements[4].progress == count) return false;
    _achievements[4] = _achievements[4].copyWith(progress: count);
    return true;
  }

  Future<void> setProgress(int index, int progress) async {
    if (index < 0 || index >= _goals.length) return;
    final goal = _goals[index];
    DateTime? date = goal.completedAt;
    final wasCompleted = goal.progress >= goal.target;
    final willComplete = progress >= goal.target;
    if (!wasCompleted && willComplete) {
      date = DateTime.now();
    } else if (!willComplete) {
      date = null;
    }
    _goals[index] = goal.copyWith(progress: progress, completedAt: date);
    await _saveProgress(index);
    _refreshCompletedGoalsAchievement();
    notifyListeners();
  }

  Future<void> resetGoal(int index) async {
    await setProgress(index, 0);
  }

  /// Increments the progress for the "mistake review" goal.
  Future<void> recordMistakeReviewed() async {
    const index = 0;
    if (index >= _goals.length) return;
    final goal = _goals[index];
    if (goal.completed) return;
    await setProgress(index, goal.progress + 1);
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

  /// Updates the "error free" streak and achievement.
  Future<void> updateErrorFreeStreak(bool correct) async {
    final next = correct ? _errorFreeStreak + 1 : 0;
    if (next == _errorFreeStreak) return;
    _errorFreeStreak = next;
    if (_achievements.length > 3) {
      _achievements[3] = _achievements[3].copyWith(progress: _errorFreeStreak);
    }
    await _saveErrorFreeStreak();
    notifyListeners();
  }

  /// Refreshes the progress values for all achievements.
  void updateAchievements({
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
    if (_achievements.length > 4 &&
        _achievements[4].progress != completedGoals) {
      _achievements[4] = _achievements[4].copyWith(progress: completedGoals);
      changed = true;
    }
    if (changed) notifyListeners();
  }
}
