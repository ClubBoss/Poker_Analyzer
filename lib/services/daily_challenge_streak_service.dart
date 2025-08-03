
class DailyChallengeStreakService {
  DailyChallengeStreakService._();

  static final DailyChallengeStreakService instance = DailyChallengeStreakService._();

  static const String _dateKey = 'lastChallengeDate';
  static const String _streakKey = 'currentStreak';

  Future<int> getCurrentStreak() async {
    final prefs = await PreferencesService.getInstance();
    return prefs.getInt(_streakKey) ?? 0;
  }

  Future<void> updateStreak() async {
    final prefs = await PreferencesService.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastStr = prefs.getString(_dateKey);
    final last = lastStr != null ? DateTime.tryParse(lastStr) : null;
    if (last != null) {
      final lastDay = DateTime(last.year, last.month, last.day);
      final diff = today.difference(lastDay).inDays;
      if (diff == 0) return;
      if (diff == 1) {
        final streak = (prefs.getInt(_streakKey) ?? 0) + 1;
        await prefs.setInt(_streakKey, streak);
      } else {
        await prefs.setInt(_streakKey, 1);
      }
    } else {
      await prefs.setInt(_streakKey, 1);
    }
    await prefs.setString(_dateKey, today.toIso8601String());
  }
}
