import 'package:shared_preferences/shared_preferences.dart';

import '../models/booster_stat_record.dart';

/// Tracks suggestion interactions per booster type for analytics.
class BoosterSuggestionStatsService {
  BoosterSuggestionStatsService._();
  static final BoosterSuggestionStatsService instance =
      BoosterSuggestionStatsService._();

  static const _prefix = 'booster_stats';

  Future<void> _increment(String type, String metric) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix.$type.$metric';
    final current = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, current + 1);
  }

  /// Records that a booster of [type] was suggested.
  Future<void> recordSuggested(String type) => _increment(type, 'suggested');

  /// Records that a booster of [type] was accepted/opened.
  Future<void> recordAccepted(String type) => _increment(type, 'accepted');

  /// Records that a booster of [type] was dismissed.
  Future<void> recordDismissed(String type) => _increment(type, 'dismissed');

  /// Returns aggregated stats for all booster types.
  Future<Map<String, BoosterStatRecord>> getStats() async {
    final prefs = await SharedPreferences.getInstance();
    final result = <String, BoosterStatRecord>{};
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_prefix)) continue;
      final parts = key.split('.');
      if (parts.length != 3) continue;
      final type = parts[1];
      final metric = parts[2];
      final count = prefs.getInt(key) ?? 0;
      final record = result[type] ??
          BoosterStatRecord(
            type: type,
            suggested: 0,
            accepted: 0,
            dismissed: 0,
          );
      switch (metric) {
        case 'suggested':
          result[type] = record.copyWith(suggested: record.suggested + count);
          break;
        case 'accepted':
          result[type] = record.copyWith(accepted: record.accepted + count);
          break;
        case 'dismissed':
          result[type] = record.copyWith(dismissed: record.dismissed + count);
          break;
      }
    }
    return result;
  }

  /// Removes all stored statistics.
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = [
      for (final k in prefs.getKeys())
        if (k.startsWith(_prefix)) k,
    ];
    for (final k in keys) {
      await prefs.remove(k);
    }
  }

  /// Exports raw stats as a json-friendly map.
  Future<Map<String, dynamic>> export() async {
    final stats = await getStats();
    return {for (final e in stats.entries) e.key: e.value.toJson()};
  }
}
