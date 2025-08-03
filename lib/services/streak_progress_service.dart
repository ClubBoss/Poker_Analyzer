
class StreakData {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActiveDate;
  final bool isTodayDone;

  const StreakData({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastActiveDate,
    required this.isTodayDone,
  });
}

class StreakProgressService {
  StreakProgressService._();
  static final StreakProgressService instance = StreakProgressService._();

  static const _lastKey = 'streak_progress_last';
  static const _currentKey = 'streak_progress_current';
  static const _longestKey = 'streak_progress_longest';

  Future<void> registerDailyActivity() async {
    final prefs = await PreferencesService.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastStr = prefs.getString(_lastKey);
    final last = lastStr != null ? DateTime.tryParse(lastStr) : null;
    var current = prefs.getInt(_currentKey) ?? 0;
    var longest = prefs.getInt(_longestKey) ?? current;

    if (last != null) {
      final lastDay = DateTime(last.year, last.month, last.day);
      final diff = today.difference(lastDay).inDays;
      if (diff == 1) {
        current += 1;
      } else if (diff > 1) {
        current = 1;
      }
    } else {
      current = 1;
    }
    if (current > longest) longest = current;

    await prefs.setInt(_currentKey, current);
    await prefs.setInt(_longestKey, longest);
    await prefs.setString(_lastKey, today.toIso8601String());
  }

  Future<StreakData> getStreak() async {
    final prefs = await PreferencesService.getInstance();
    final current = prefs.getInt(_currentKey) ?? 0;
    final longest = prefs.getInt(_longestKey) ?? 0;
    final lastStr = prefs.getString(_lastKey);
    final last = lastStr != null ? DateTime.tryParse(lastStr) : null;
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final isTodayDone =
        last != null &&
        DateTime(last.year, last.month, last.day).difference(today).inDays == 0;
    return StreakData(
      currentStreak: current,
      longestStreak: longest,
      lastActiveDate: last,
      isTodayDone: isTodayDone,
    );
  }
}
