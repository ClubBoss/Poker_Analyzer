
/// Manages completion history for Daily Challenges.
class DailyChallengeHistoryService {
  DailyChallengeHistoryService._();

  /// Singleton instance.
  static final DailyChallengeHistoryService instance =
      DailyChallengeHistoryService._();

  static const String _historyKey = 'daily_challenge_history';

  /// Returns the list of completion dates.
  Future<List<DateTime>> loadHistory() async {
    final prefs = await PreferencesService.getInstance();
    final raw = prefs.getStringList(_historyKey) ?? [];
    return [
      for (final s in raw)
        if (DateTime.tryParse(s) != null) DateTime.parse(s)
    ];
  }

  /// Convenience method returning a set of days without time component.
  Future<Set<DateTime>> loadHistorySet() async {
    final list = await loadHistory();
    return {for (final d in list) DateTime(d.year, d.month, d.day)};
  }

  /// Adds today's date to the history if absent.
  Future<void> addToday() async {
    final prefs = await PreferencesService.getInstance();
    final list = prefs.getStringList(_historyKey) ?? [];
    final now = DateTime.now();
    final todayStr = DateTime(now.year, now.month, now.day).toIso8601String();
    if (!list.contains(todayStr)) {
      list.add(todayStr);
      // Keep up to 60 entries to limit storage growth.
      if (list.length > 60) {
        list.removeRange(0, list.length - 60);
      }
      await prefs.setStringList(_historyKey, list);
    }
  }
}
