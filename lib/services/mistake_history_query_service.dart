import '../models/recall_success_entry.dart';
import '../models/mistake_history_entry.dart';
import 'decay_hotspot_stats_aggregator_service.dart'
    show RecallFailureSpottingLoader, SpotTagResolver, RecallSuccessLoader;

typedef SpotStreetResolver = Future<String?> Function(String spotId);

class MistakeHistoryQueryService {
  final RecallFailureSpottingLoader loadSpottings;
  final SpotTagResolver resolveTags;
  final SpotStreetResolver resolveStreet;
  final RecallSuccessLoader? loadSuccesses;

  const MistakeHistoryQueryService({
    required this.loadSpottings,
    required this.resolveTags,
    required this.resolveStreet,
    this.loadSuccesses,
  });

  Future<List<MistakeHistoryEntry>> queryMistakes({
    String? tag,
    String? street,
    String? spotIdPattern,
    int limit = 20,
  }) async {
    if (limit <= 0) return [];
    final spottings = await loadSpottings();
    final successes =
        loadSuccesses != null ? await loadSuccesses!() : <RecallSuccessEntry>[];

    final successMap = <String, List<DateTime>>{};
    for (final s in successes) {
      final t = s.tag.trim().toLowerCase();
      if (t.isEmpty) continue;
      successMap.putIfAbsent(t, () => []).add(s.timestamp);
    }

    final normTag = tag?.trim().toLowerCase();
    final normStreet = street?.trim().toLowerCase();
    final normPattern = spotIdPattern?.trim().toLowerCase();

    final List<MistakeHistoryEntry> entries = [];

    for (final s in spottings) {
      if (entries.length >= limit) break;
      final spotTags = (await resolveTags(s.spotId))
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toList();
      if (spotTags.isEmpty) continue;

      String? spotStreet;
      if (normStreet != null && normStreet.isNotEmpty) {
        spotStreet = (await resolveStreet(s.spotId))?.trim().toLowerCase();
        if (spotStreet != normStreet) continue;
      }

      if (normPattern != null && normPattern.isNotEmpty) {
        if (!s.spotId.toLowerCase().contains(normPattern)) continue;
      }

      for (final t in spotTags) {
        if (normTag != null && normTag.isNotEmpty && t != normTag) {
          continue;
        }
        final successesForTag = successMap[t];
        bool recovered = false;
        if (successesForTag != null) {
          recovered = successesForTag.any((ts) => ts.isAfter(s.timestamp));
        }
        entries.add(MistakeHistoryEntry(
          spotId: s.spotId,
          timestamp: s.timestamp,
          decayStage: s.decayStage,
          tag: t,
          wasRecovered: recovered,
        ));
        if (entries.length >= limit) break;
      }
    }

    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (entries.length > limit) {
      return entries.take(limit).toList();
    }
    return entries;
  }
}
