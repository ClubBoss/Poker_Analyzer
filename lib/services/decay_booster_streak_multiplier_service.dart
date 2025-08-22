import 'decay_streak_tracker_service.dart';

/// Provides reward multipliers for decay boosters based on streak length.
class DecayBoosterStreakMultiplierService {
  final DecayStreakTrackerService tracker;

  DecayBoosterStreakMultiplierService({
    this.tracker = const DecayStreakTrackerService(),
  });

  /// Returns +1 reward multiplier for every 5 days in the current streak.
  Future<int> getStreakRewardMultiplier() async {
    final streak = await tracker.getCurrentStreak();
    return streak ~/ 5;
  }

  /// Scales a coin reward by adding the streak multiplier.
  Future<int> scaleCoins(int baseAmount) async {
    final m = await getStreakRewardMultiplier();
    return baseAmount + m;
  }

  /// Scales an XP reward by adding the streak multiplier.
  Future<int> scaleXp(int baseAmount) async {
    final m = await getStreakRewardMultiplier();
    return baseAmount + m;
  }
}
