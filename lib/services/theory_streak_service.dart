import 'package:shared_preferences/shared_preferences.dart';

import 'theory_reinforcement_log_service.dart';

class TheoryStreakService {
  TheoryStreakService._();

  static final TheoryStreakService instance = TheoryStreakService._();

  static const String _countKey = 'theory_streak_count';
  static const String _bestKey = 'theory_streak_best';

  Future<int> getCurrentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final logs = await TheoryReinforcementLogService.instance.getRecent(
      within: const Duration(days: 60),
    );
    final days = <String>{};
    for (final l in logs) {
      final d = DateTime(l.timestamp.year, l.timestamp.month, l.timestamp.day)
          .toIso8601String()
          .split('T')
          .first;
      days.add(d);
    }
    final today = DateTime.now();
    int streak = 0;
    for (var i = 0;; i++) {
      final day = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: i))
          .toIso8601String()
          .split('T')
          .first;
      if (days.contains(day)) {
        streak += 1;
      } else {
        break;
      }
    }
    await prefs.setInt(_countKey, streak);
    final best = prefs.getInt(_bestKey) ?? 0;
    if (streak > best) await prefs.setInt(_bestKey, streak);
    return streak;
  }

  Future<int> getMaxStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_bestKey) ?? 0;
  }
}
