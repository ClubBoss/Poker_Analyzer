import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  GoalsService();

  late List<Goal> _goals;

  List<Goal> get goals => List.unmodifiable(_goals);

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
}
