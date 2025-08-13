import '../models/recall_failure_spotting.dart';
import '../models/recall_success_entry.dart';
import '../models/decay_hotspot_stats.dart';

typedef RecallFailureSpottingLoader = Future<List<RecallFailureSpotting>>
    Function();
typedef SpotTagResolver = Future<List<String>> Function(String spotId);
typedef RecallSuccessLoader = Future<List<RecallSuccessEntry>> Function();

class DecayHotspotStatsAggregatorService {
  final RecallFailureSpottingLoader loadSpottings;
  final SpotTagResolver resolveTags;
  final RecallSuccessLoader? loadSuccesses;

  const DecayHotspotStatsAggregatorService({
    required this.loadSpottings,
    required this.resolveTags,
    this.loadSuccesses,
  });

  Future<DecayHotspotStats> generateStats({int top = 5}) async {
    if (top <= 0) {
      return const DecayHotspotStats(topTags: [], topSpotIds: []);
    }
    final spottings = await loadSpottings();
    final tagMap = <String, _StatCollector>{};
    final spotMap = <String, _StatCollector>{};
    final tagCache = <String, List<String>>{};

    for (final s in spottings) {
      final spotCollector =
          spotMap.putIfAbsent(s.spotId, () => _StatCollector())..add(s);
      final tags = tagCache[s.spotId] ??= await resolveTags(s.spotId);
      for (final t in tags) {
        final key = t.trim().toLowerCase();
        if (key.isEmpty) continue;
        tagMap.putIfAbsent(key, () => _StatCollector()).add(s);
      }
    }

    final successCount = <String, int>{};
    if (loadSuccesses != null) {
      final successes = await loadSuccesses!();
      for (final e in successes) {
        final tag = e.tag.trim().toLowerCase();
        if (tag.isEmpty) continue;
        successCount.update(tag, (v) => v + 1, ifAbsent: () => 1);
      }
    }

    final tagStats = tagMap.entries.map((e) {
      final failures = e.value.count;
      final successes = successCount[e.key] ?? 0;
      final total = successes + failures;
      final rate = total > 0 ? successes / total : null;
      return DecayHotspotStat(
        id: e.key,
        count: failures,
        successRate: rate,
        lastSeen: e.value.lastSeen ?? DateTime.fromMillisecondsSinceEpoch(0),
        decayStageDistribution: Map.unmodifiable(e.value.decayStages),
      );
    }).toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    final spotStats = spotMap.entries
        .map((e) => DecayHotspotStat(
              id: e.key,
              count: e.value.count,
              successRate: null,
              lastSeen:
                  e.value.lastSeen ?? DateTime.fromMillisecondsSinceEpoch(0),
              decayStageDistribution: Map.unmodifiable(e.value.decayStages),
            ))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return DecayHotspotStats(
      topTags: tagStats.take(top).toList(),
      topSpotIds: spotStats.take(top).toList(),
    );
  }
}

class _StatCollector {
  int count = 0;
  DateTime? lastSeen;
  final Map<String, int> decayStages = {};

  void add(RecallFailureSpotting s) {
    count += 1;
    if (lastSeen == null || s.timestamp.isAfter(lastSeen!)) {
      lastSeen = s.timestamp;
    }
    final stage = s.decayStage.trim();
    if (stage.isNotEmpty) {
      decayStages.update(stage, (v) => v + 1, ifAbsent: () => 1);
    }
  }
}
