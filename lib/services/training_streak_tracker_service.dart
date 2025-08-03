
/// Tracks days when the user completed at least one training session.
/// Provides current and maximum streak information.
class TrainingStreakTrackerService {
  TrainingStreakTrackerService._();
  static final TrainingStreakTrackerService instance =
      TrainingStreakTrackerService._();

  static const _datesKey = 'training_streak_days';

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<DateTime> _parseDates(List<String> list) {
    return list
        .map((e) => DateTime.tryParse(e))
        .whereType<DateTime>()
        .map((d) => DateTime(d.year, d.month, d.day))
        .toList()
      ..sort();
  }

  Future<void> markTrainingCompletedToday() async {
    final prefs = await PreferencesService.getInstance();
    final days = prefs.getStringList(_datesKey) ?? <String>[];
    final today = DateTime.now();
    final todayStr = _fmt(today);
    if (!days.contains(todayStr)) {
      days.add(todayStr);
      days.sort();
      await prefs.setStringList(_datesKey, days);
    }
  }

  Future<int> getCurrentStreak() async {
    final prefs = await PreferencesService.getInstance();
    final dates = _parseDates(prefs.getStringList(_datesKey) ?? <String>[]);
    if (dates.isEmpty) return 0;
    final set = dates.toSet();
    var day = DateTime.now();
    day = DateTime(day.year, day.month, day.day);
    int streak = 0;
    while (set.contains(day)) {
      streak += 1;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Future<int> getMaxStreak() async {
    final prefs = await PreferencesService.getInstance();
    final dates = _parseDates(prefs.getStringList(_datesKey) ?? <String>[]);
    if (dates.isEmpty) return 0;
    int best = 1;
    int current = 1;
    for (var i = 1; i < dates.length; i++) {
      final diff = dates[i].difference(dates[i - 1]).inDays;
      if (diff == 1) {
        current += 1;
      } else if (diff > 1) {
        if (current > best) best = current;
        current = 1;
      }
    }
    if (current > best) best = current;
    return best;
  }

  /// Returns a map with all stored dates and streak info for analytics.
  Future<Map<String, dynamic>> exportData() async {
    final prefs = await PreferencesService.getInstance();
    final days = prefs.getStringList(_datesKey) ?? <String>[];
    final current = await getCurrentStreak();
    final max = await getMaxStreak();
    return {
      'days': days,
      'currentStreak': current,
      'maxStreak': max,
    };
  }
}
