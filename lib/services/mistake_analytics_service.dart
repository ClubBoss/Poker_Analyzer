import 'mistake_tag_history_service.dart';

class MistakeTagData {
  final String tag;
  final int mistakeCount;
  final double evLoss;

  const MistakeTagData({
    required this.tag,
    required this.mistakeCount,
    required this.evLoss,
  });
}

/// Provides analytics on recent mistakes.
class MistakeAnalyticsService {
  const MistakeAnalyticsService();

  /// Returns stats for top mistake tags sorted by frequency.
  Future<List<MistakeTagData>> getTopMistakeTags({int max = 5}) async {
    if (max <= 0) return <MistakeTagData>[];
    final freq = await MistakeTagHistoryService.getTagsByFrequency();
    final entries = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final results = <MistakeTagData>[];
    for (final e in entries) {
      if (results.length >= max) break;
      final recent = await MistakeTagHistoryService.getRecentMistakesByTag(
        e.key,
        limit: 50,
      );
      double loss = 0;
      for (final r in recent) {
        if (r.evDiff < 0) loss += -r.evDiff;
      }
      results.add(
        MistakeTagData(
          tag: e.key.label.toLowerCase(),
          mistakeCount: e.value,
          evLoss: loss,
        ),
      );
    }
    results.sort((a, b) {
      final cmp = b.mistakeCount.compareTo(a.mistakeCount);
      if (cmp != 0) return cmp;
      return b.evLoss.compareTo(a.evLoss);
    });
    return results;
  }
}
