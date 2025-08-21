import 'package:shared_preferences/shared_preferences.dart';

import 'decay_streak_tracker_service.dart';
import '../models/decay_streak_badge.dart';

/// Detects when the user reaches a new decay streak milestone.
class DecayStreakBadgeNotifier {
  final DecayStreakTrackerService tracker;

  DecayStreakBadgeNotifier({DecayStreakTrackerService? tracker})
      : tracker = tracker ?? const DecayStreakTrackerService();

  static const _milestones = [3, 7, 14, 30];
  static const _key = 'decay_streak_last_milestone';

  /// Returns a badge for a newly reached milestone or `null`.
  Future<DecayStreakBadge?> checkForBadge() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_key) ?? 0;
    final streak = await tracker.getCurrentStreak();
    for (final m in _milestones) {
      if (streak >= m && m > last) {
        await prefs.setInt(_key, m);
        return DecayStreakBadge(m);
      }
    }
    return null;
  }
}
