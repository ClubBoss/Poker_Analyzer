
class TheoryStreakService {
  TheoryStreakService._();

  static final TheoryStreakService instance = TheoryStreakService._();

  static const String _lastKey = 'theory_streak_last';
  static const String _countKey = 'theory_streak_count';
  static const String _bestKey = 'theory_streak_best';

  Future<int> getCurrentStreak() async {
    final prefs = await PreferencesService.getInstance();
    return prefs.getInt(_countKey) ?? 0;
  }

  Future<int> getMaxStreak() async {
    final prefs = await PreferencesService.getInstance();
    return prefs.getInt(_bestKey) ?? 0;
  }

  Future<void> recordToday() async {
    final prefs = await PreferencesService.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastStr = prefs.getString(_lastKey);
    final last = lastStr != null ? DateTime.tryParse(lastStr) : null;
    var current = prefs.getInt(_countKey) ?? 0;
    var best = prefs.getInt(_bestKey) ?? current;

    if (last != null) {
      final lastDay = DateTime(last.year, last.month, last.day);
      final diff = today.difference(lastDay).inDays;
      if (diff == 0) {
        // already recorded today
        return;
      } else if (diff == 1) {
        current += 1;
      } else if (diff > 1) {
        current = 1;
      }
    } else {
      current = 1;
    }

    if (current > best) best = current;

    await prefs.setInt(_countKey, current);
    await prefs.setInt(_bestKey, best);
    await prefs.setString(_lastKey, today.toIso8601String());
  }
}
