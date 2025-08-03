import '../services/generated_pack_history_service.dart';

/// Utilities for working with generated pack history.
class GeneratedPackHistoryUtils {
  /// Deduplicates [history] by keeping the most recent entry for each pack id
  /// and returning the results sorted by descending timestamp.
  static List<GeneratedPackInfo> deduplicate(
      List<GeneratedPackInfo> history) {
    final map = <String, GeneratedPackInfo>{};
    for (final h in history) {
      final existing = map[h.id];
      if (existing == null || h.ts.isAfter(existing.ts)) {
        map[h.id] = h;
      }
    }
    final list = map.values.toList()
      ..sort((a, b) => b.ts.compareTo(a.ts));
    return list;
  }
}
