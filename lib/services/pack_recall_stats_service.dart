import 'package:shared_preferences/shared_preferences.dart';

/// Logs review timestamps for each training pack to analyze recall intervals.
class PackRecallStatsService {
  PackRecallStatsService._();

  /// Singleton instance.
  static final PackRecallStatsService instance = PackRecallStatsService._();

  static const String _prefix = 'pack_recall_history';

  /// Records a review time for [packId].
  Future<void> recordReview(String packId, DateTime time) async {
    if (packId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix.$packId';
    final list = prefs.getStringList(key) ?? <String>[];
    list.add(time.toIso8601String());
    while (list.length > 50) {
      list.removeAt(0);
    }
    await prefs.setStringList(key, list);
  }

  /// Returns the stored review history for [packId], oldest first.
  Future<List<DateTime>> getReviewHistory(String packId) async {
    if (packId.isEmpty) return <DateTime>[];
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix.$packId';
    final list = prefs.getStringList(key) ?? <String>[];
    return [
      for (final s in list)
        if (DateTime.tryParse(s) != null) DateTime.parse(s),
    ];
  }

  /// Returns the average interval between reviews of [packId].
  Future<Duration?> averageReviewInterval(String packId) async {
    final history = await getReviewHistory(packId);
    if (history.length < 2) return null;
    history.sort();
    var total = Duration.zero;
    for (var i = 1; i < history.length; i++) {
      total += history[i].difference(history[i - 1]);
    }
    return total ~/ (history.length - 1);
  }

  /// Returns pack ids with a review coming up within [leadTime].
  Future<List<String>> upcomingReviewPacks({
    Duration leadTime = const Duration(days: 3),
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final ids = <String>[];
    const prefix = '$_prefix.';
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(prefix)) continue;
      final id = key.substring(prefix.length);
      final history = await getReviewHistory(id);
      if (history.length < 2) continue;
      final avg = await averageReviewInterval(id);
      if (avg == null) continue;
      final next = history.last.add(avg);
      if (next.isAfter(now) && next.difference(now) <= leadTime) {
        ids.add(id);
      }
    }
    return ids;
  }
}
