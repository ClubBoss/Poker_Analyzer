import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_goal.dart';
import '../widgets/confetti_overlay.dart';
import '../main.dart';
import 'training_stats_service.dart';

class GoalEngine extends ChangeNotifier {
  static const _prefsKey = 'user_goals';
  final TrainingStatsService stats;
  GoalEngine({required this.stats}) {
    _init();
  }

  final List<UserGoal> _goals = [];

  List<UserGoal> get goals => List.unmodifiable(_goals);

  Future<void> _init() async {
    await _load();
    _update();
    stats.sessionsStream.listen((_) => _update());
    stats.handsStream.listen((_) => _update());
    stats.mistakesStream.listen((_) => _update());
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      _goals
        ..clear()
        ..addAll(UserGoal.decode(raw));
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, UserGoal.encode(_goals));
  }

  int _statValue(String type) {
    switch (type) {
      case 'sessions':
        return stats.sessionsCompleted;
      case 'hands':
        return stats.handsReviewed;
      default:
        return stats.mistakesFixed;
    }
  }

  int progress(UserGoal g) => _statValue(g.type) - g.base;

  void _update() {
    for (var i = 0; i < _goals.length; i++) {
      final g = _goals[i];
      if (!g.completed && progress(g) >= g.target) {
        _goals[i] = g.copyWith(completedAt: DateTime.now());
        _save();
        final ctx = navigatorKey.currentContext;
        if (ctx != null) {
          showConfettiOverlay(ctx);
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text('Goal completed: ${g.title}')),
          );
        }
      }
    }
    notifyListeners();
  }

  Future<void> addGoal(UserGoal g) async {
    _goals.add(g);
    await _save();
    notifyListeners();
  }

  Future<void> removeGoal(String id) async {
    _goals.removeWhere((g) => g.id == id);
    await _save();
    notifyListeners();
  }
}
