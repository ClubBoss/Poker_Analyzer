import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import 'coins_service.dart';
import 'xp_reward_engine.dart';

/// Tracks consecutive days with completed training sessions
/// and triggers rewards at specific thresholds.
class SessionStreakTrackerService {
  SessionStreakTrackerService._();
  static final SessionStreakTrackerService instance =
      SessionStreakTrackerService._();

  static const _lastDateKey = 'session_streak_last';
  static const _countKey = 'session_streak_count';
  static const _avatarBonusKey = 'session_streak_avatar_bonus';

  Future<int> getCurrentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_countKey) ?? 0;
  }

  Future<void> markCompletedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastStr = prefs.getString(_lastDateKey);
    final last = lastStr != null ? DateTime.tryParse(lastStr) : null;
    int streak = prefs.getInt(_countKey) ?? 0;
    if (last != null) {
      final lastDay = DateTime(last.year, last.month, last.day);
      final diff = today.difference(lastDay).inDays;
      if (diff == 0) {
        return;
      } else if (diff == 1) {
        streak += 1;
      } else {
        streak = 1;
      }
    } else {
      streak = 1;
    }
    await prefs.setInt(_countKey, streak);
    await prefs.setString(_lastDateKey, today.toIso8601String());
  }

  Future<void> checkAndTriggerRewards() async {
    final prefs = await SharedPreferences.getInstance();
    final ctx = navigatorKey.currentContext;
    final streak = prefs.getInt(_countKey) ?? 0;
    bool updated = false;
    if (streak >= 3 && !(prefs.getBool('reward_3') ?? false)) {
      await CoinsService.instance.addCoins(10);
      if (ctx != null) {
        ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(content: Text('+10 coins for 3-day streak!')));
      }
      await prefs.setBool('reward_3', true);
      updated = true;
    }
    if (streak >= 5 && !(prefs.getBool('reward_5') ?? false)) {
      await XPRewardEngine.instance.addXp(20);
      if (ctx != null) {
        ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(content: Text('+20 XP for 5-day streak!')));
      }
      await prefs.setBool('reward_5', true);
      updated = true;
    }
    if (streak >= 10 && !(prefs.getBool('reward_10') ?? false)) {
      await CoinsService.instance.addCoins(50);
      await prefs.setBool(_avatarBonusKey, true);
      if (ctx != null) {
        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
            content: Text(
                '🔥 10-day streak! +50 coins and avatar bonus unlocked!')));
      }
      await prefs.setBool('reward_10', true);
      updated = true;
    }
    if (updated) {
      // Persisted via prefs already
    }
  }
}
