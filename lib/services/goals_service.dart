import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final IconData? icon;

  const Goal({
    required this.title,
    required this.progress,
    required this.target,
    this.icon,
  });

  Goal copyWith({int? progress, int? target}) => Goal(
        title: title,
        progress: progress ?? this.progress,
        target: target ?? this.target,
        icon: icon,
      );
}

class GoalsService extends ChangeNotifier {
  static const _prefPrefix = 'goal_progress_';

  /// In-memory list of all achievements.
  late List<Achievement> _achievements;

  static GoalsService? _instance;
  static GoalsService? get instance => _instance;

  GoalsService() {
    _instance = this;
  }

  late List<Goal> _goals;

  List<Goal> get goals => List.unmodifiable(_goals);

  List<Achievement> get achievements => List.unmodifiable(_achievements);

  bool get anyCompleted => _goals.any((g) => g.progress >= g.target);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _goals = [
      Goal(
        title: 'Разобрать 5 ошибок',
        progress: prefs.getInt('${_prefPrefix}0') ?? 0,
        target: 5,
        icon: Icons.bug_report,
      ),
      Goal(
        title: 'Пройти 3 раздачи без ошибок подряд',
        progress: prefs.getInt('${_prefPrefix}1') ?? 0,
        target: 3,
        icon: Icons.play_circle_fill,
      ),
    ];
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
    ];
    notifyListeners();
  }

  Future<void> _saveProgress(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_prefPrefix}$index', _goals[index].progress);
  }

  Future<void> setProgress(int index, int progress) async {
    if (index < 0 || index >= _goals.length) return;
    _goals[index] = _goals[index].copyWith(progress: progress);
    await _saveProgress(index);
    notifyListeners();
  }

  Future<void> resetGoal(int index) async {
    await setProgress(index, 0);
  }

  /// Refreshes the progress values for all achievements.
  void updateAchievements({
    required int correctHands,
    required int streakDays,
    required bool goalCompleted,
  }) {
    bool changed = false;
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
    if (changed) notifyListeners();
  }
}
