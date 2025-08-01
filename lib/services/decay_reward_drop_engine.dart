import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../widgets/confetti_overlay.dart';
import 'coins_service.dart';
import 'decay_streak_tracker_service.dart';
import 'decay_reward_analytics_service.dart';
import 'motivation_service.dart';

/// Randomly shows a small reward after finishing decay boosters.
class DecayRewardDropEngine {
  DecayRewardDropEngine._({
    DecayStreakTrackerService? streaks,
    Random? random,
  })  : streaks = streaks ?? const DecayStreakTrackerService(),
        _random = random ?? Random();

  /// Singleton instance.
  static final DecayRewardDropEngine instance = DecayRewardDropEngine._();

  final DecayStreakTrackerService streaks;
  final Random _random;

  static const double minChance = 0.10;
  static const double maxChance = 0.20;
  static const _countKey = 'decay_reward_drop_count';
  static const _lastKey = 'decay_reward_drop_last';

  /// Triggers a surprise reward with 10-20% chance when on a decay streak.
  /// Optionally logs rewards for [tags].
  Future<void> maybeTriggerReward(
    BuildContext context, {
    List<String>? tags,
  }) async {
    final streak = await streaks.getCurrentStreak();
    if (streak <= 0) return;

    final chance = minChance + _random.nextDouble() * (maxChance - minChance);
    if (_random.nextDouble() > chance) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_countKey, (prefs.getInt(_countKey) ?? 0) + 1);
    await prefs.setString(_lastKey, DateTime.now().toIso8601String());

    final rewardType = _random.nextInt(3); // 0: confetti, 1: quote, 2: coins
    String rewardLabel;
    switch (rewardType) {
      case 0:
        showConfettiOverlay(context);
        rewardLabel = 'confetti';
        break;
      case 1:
        final quote = await MotivationService.getDailyQuote();
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('⭐ $quote')));
        }
        rewardLabel = 'quote';
        break;
      default:
        const amount = 5;
        await CoinsService.instance.addCoins(amount);
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('🪙 +5 coins!')));
        }
        rewardLabel = 'coins';
    }

    if (tags != null) {
      for (final t in tags) {
        await DecayRewardAnalyticsService.instance.logReward(t, rewardLabel);
      }
    }
  }
}
