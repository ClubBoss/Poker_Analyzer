import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/confetti_overlay.dart';
import 'dev_console_log_service.dart';
import 'training_streak_tracker_service.dart';
import 'xp_reward_engine.dart';
import '../main.dart';

/// Rewards users for reaching training streak milestones.
class StreakRewardEngine {
  StreakRewardEngine._();
  static final StreakRewardEngine instance = StreakRewardEngine._();

  static const _rewardKey = 'streak_reward_levels';
  static const Map<int, int> _rewards = {
    3: 25,
    7: 50,
    14: 75,
    30: 100,
    60: 150,
    100: 200,
  };

  Future<void> checkAndTriggerRewards() async {
    final prefs = await SharedPreferences.getInstance();
    final unlocked = prefs.getStringList(_rewardKey) ?? <String>[];
    final current = await TrainingStreakTrackerService.instance
        .getCurrentStreak();
    bool updated = false;
    for (final entry in _rewards.entries) {
      final level = entry.key;
      if (current >= level && !unlocked.contains(level.toString())) {
        final xp = entry.value;
        unlocked.add(level.toString());
        updated = true;
        DevConsoleLogService.instance.log(
          'Streak reward unlocked: $level days',
        );
        await XPRewardEngine.instance.addXp(xp);
        final ctx = navigatorKey.currentContext;
        if (ctx != null) {
          showConfettiOverlay(ctx);
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text('🔥 $level-day streak! +$xp XP')),
          );
        }
      }
    }
    if (updated) {
      await prefs.setStringList(_rewardKey, unlocked);
    }
  }
}
