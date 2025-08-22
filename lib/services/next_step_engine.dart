import 'package:flutter/material.dart';
import 'saved_hand_manager_service.dart';
import 'user_goal_engine.dart';
import 'streak_service.dart';
import '../models/saved_hand.dart';
import '../models/user_goal.dart';

class NextStepSuggestion {
  final String title;
  final IconData icon;
  final String message;
  final String targetRoute;
  NextStepSuggestion({
    required this.title,
    required this.icon,
    required this.message,
    required this.targetRoute,
  });
}

class NextStepEngine extends ChangeNotifier {
  static NextStepEngine? _instance;
  static NextStepEngine get instance => _instance!;

  final SavedHandManagerService hands;
  final UserGoalEngine goals;
  final StreakService streak;
  NextStepSuggestion? _suggestion;
  NextStepSuggestion? get suggestion => _suggestion;

  NextStepEngine({
    required this.hands,
    required this.goals,
    required this.streak,
  }) {
    _instance = this;
    _update();
    hands.addListener(_update);
    goals.addListener(_update);
    streak.addListener(_update);
  }

  bool _isMistake(SavedHand h) {
    final exp = h.expectedAction?.trim().toLowerCase();
    final gto = h.gtoAction?.trim().toLowerCase();
    return exp != null &&
        gto != null &&
        exp.isNotEmpty &&
        gto.isNotEmpty &&
        exp != gto;
  }

  NextStepSuggestion? _compute() {
    final list = hands.hands;
    for (var i = list.length - 1; i >= 0; i--) {
      final h = list[i];
      if (_isMistake(h)) {
        String tag = h.tags.isNotEmpty ? h.tags.first : h.name;
        if (tag.isEmpty) tag = 'Раздача';
        return NextStepSuggestion(
          title: 'Повтори ошибку',
          icon: Icons.replay,
          message: tag,
          targetRoute: '/mistake_repeat',
        );
      }
    }
    UserGoal? best;
    int remain = 1 << 30;
    for (final g in goals.goals) {
      final left = g.target - goals.progress(g);
      if (left > 0 && left < remain) {
        remain = left;
        best = g;
      }
    }
    if (best != null && remain <= 2) {
      return NextStepSuggestion(
        title: 'Закрой цель',
        icon: Icons.flag,
        message: 'Осталось $remain до ${best.target}',
        targetRoute: '/goals',
      );
    }
    final ef = streak.errorFreeStreak;
    if (ef > 0 && ef < 5) {
      return const NextStepSuggestion(
        title: 'Продолжи серию',
        icon: Icons.flash_on,
        message: 'Ещё немного до 5/5',
        targetRoute: '/spot_of_the_day',
      );
    }
    return null;
  }

  void _update() {
    final next = _compute();
    if (next == null && _suggestion == null) return;
    if (next == null ||
        _suggestion == null ||
        next.title != _suggestion!.title ||
        next.message != _suggestion!.message) {
      _suggestion = next;
      notifyListeners();
    }
  }
}
