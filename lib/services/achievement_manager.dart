import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/achievement_unlocked_overlay.dart';
import '../models/drill_session_result.dart';
import 'goal_persistence.dart';
import 'xp_tracker_service.dart';

class Achievement {
  final String title;
  final IconData icon;
  final int progress;
  final int target;
  final DateTime? completedAt;

  const Achievement({
    required this.title,
    required this.icon,
    required this.progress,
    required this.target,
    this.completedAt,
  });

  bool get completed => progress >= target;

  Achievement copyWith({int? progress, DateTime? completedAt}) => Achievement(
    title: title,
    icon: icon,
    progress: progress ?? this.progress,
    target: target,
    completedAt: completedAt ?? this.completedAt,
  );
}

/// Handles achievement progress and notifications.
class AchievementManager {
  AchievementManager(this.persistence);

  final GoalPersistence persistence;
  late List<Achievement> _achievements;
  late List<bool> _achievementShown;

  List<Achievement> get achievements => List.unmodifiable(_achievements);

  Future<void> init({
    required int errorFreeStreak,
    required int mistakeReviewStreak,
    required int completedGoals,
    required bool allGoalsCompleted,
    required int drillMaster,
  }) async {
    _achievements = [
      const Achievement(
        title: 'Разобрать 10 ошибок',
        icon: Icons.bug_report,
        progress: 0,
        target: 10,
      ),
      const Achievement(
        title: 'Пройти 3 дня подряд',
        icon: Icons.calendar_today,
        progress: 0,
        target: 3,
      ),
      const Achievement(
        title: 'Выполнить цель дня',
        icon: Icons.flag,
        progress: 0,
        target: 1,
      ),
      Achievement(
        title: 'Серия без ошибок',
        icon: Icons.bolt,
        progress: errorFreeStreak,
        target: 10,
      ),
      Achievement(
        title: 'Выполнить 5 целей',
        icon: Icons.star,
        progress: completedGoals,
        target: 5,
      ),
      Achievement(
        title: 'Серия разборов',
        icon: Icons.history,
        progress: mistakeReviewStreak,
        target: 7,
      ),
      Achievement(
        title: 'Все цели выполнены',
        icon: Icons.done_all,
        progress: allGoalsCompleted ? 1 : 0,
        target: 1,
      ),
      Achievement(
        title: '100 без ошибок',
        icon: Icons.flash_on,
        progress: errorFreeStreak,
        target: 100,
      ),
      const Achievement(
        title: '7-дневная серия',
        icon: Icons.calendar_month,
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
    _achievementShown = await persistence.loadAchievementShown(
      _achievements.length,
    );
  }

  Achievement _withProgress(Achievement a, int progress) {
    DateTime? date = a.completedAt;
    if (date == null && progress >= a.target) {
      date = DateTime.now();
    }
    return a.copyWith(progress: progress, completedAt: date);
  }

  void checkAchievements(BuildContext context) {
    for (
      var i = 0;
      i < _achievements.length && i < _achievementShown.length;
      i++
    ) {
      if (!_achievementShown[i] && _achievements[i].completed) {
        _achievementShown[i] = true;
        persistence.saveAchievementShown(i);
        context.read<XPTrackerService>().add(
          xp: XPTrackerService.achievementXp,
          source: 'achievement',
        );
        if (context.mounted) {
          showAchievementUnlockedOverlay(
            context,
            _achievements[i].icon,
            _achievements[i].title,
          );
        }
      }
    }
  }

  bool refreshCompletedGoalsAchievement(int completedGoals, int totalGoals) {
    if (_achievements.length < 5) return false;
    bool changed = false;
    if (_achievements[4].progress != completedGoals) {
      _achievements[4] = _withProgress(_achievements[4], completedGoals);
      changed = true;
    }
    if (_achievements.length > 6) {
      final all = completedGoals == totalGoals ? 1 : 0;
      if (_achievements[6].progress != all) {
        _achievements[6] = _withProgress(_achievements[6], all);
        changed = true;
      }
    }
    return changed;
  }

  void updateMistakeReviewStreakAchievement(int progress) {
    if (_achievements.length > 5) {
      _achievements[5] = _withProgress(_achievements[5], progress);
    }
  }

  void updateErrorFreeStreakAchievement(int streak) {
    if (_achievements.length > 3) {
      _achievements[3] = _withProgress(_achievements[3], streak);
    }
    if (_achievements.length > 7) {
      _achievements[7] = _withProgress(_achievements[7], streak);
    }
  }

  bool updateAchievements({
    BuildContext? context,
    required int correctHands,
    required int streakDays,
    required bool goalCompleted,
    required int completedGoals,
    required int totalGoals,
  }) {
    bool changed = false;
    final values = [correctHands, streakDays, goalCompleted ? 1 : 0];
    for (var i = 0; i < _achievements.length && i < values.length; i++) {
      final updated = _withProgress(_achievements[i], values[i]);
      if (_achievements[i].progress != updated.progress) {
        changed = true;
        _achievements[i] = updated;
      }
    }
    if (_achievements.length > 8 && _achievements[8].progress != streakDays) {
      _achievements[8] = _withProgress(_achievements[8], streakDays);
      changed = true;
    }
    changed =
        refreshCompletedGoalsAchievement(completedGoals, totalGoals) || changed;
    if (_achievements.length > 6) {
      final all = completedGoals == totalGoals ? 1 : 0;
      if (_achievements[6].progress != all) {
        _achievements[6] = _withProgress(_achievements[6], all);
        changed = true;
      }
    }
    if (changed) {
      if (context != null) checkAchievements(context);
    }
    return changed;
  }

  void updateDrillAchievement(List<DrillSessionResult> results) {
    if (_achievements.length < 10) return;
    int value = 0;
    if (results.length >= 5) {
      final last = results.reversed.take(5).toList();
      final avg =
          last.map((e) => e.accuracy).reduce((a, b) => a + b) / last.length;
      if (avg >= 0.8) value = 1;
    }
    if (_achievements[9].progress != value) {
      _achievements[9] = _withProgress(_achievements[9], value);
    }
  }
}
