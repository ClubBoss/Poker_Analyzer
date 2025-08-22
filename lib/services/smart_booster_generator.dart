import 'package:uuid/uuid.dart';

import '../models/mistake_tag_cluster.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/game_type.dart';
import '../core/training/library/training_pack_library_v2.dart';
import '../core/training/engine/training_type_engine.dart';
import 'mistake_tag_insights_service.dart';
import 'mistake_tag_cluster_service.dart';
import 'training_history_service_v2.dart';

class SmartBoosterGenerator {
  final MistakeTagInsightsService insightsService;
  final MistakeTagClusterService clusterService;

  SmartBoosterGenerator({
    this.insightsService = const MistakeTagInsightsService(),
    this.clusterService = const MistakeTagClusterService(),
  });

  Future<List<TrainingPackTemplateV2>> generate({
    int maxPacks = 3,
    int maxSpots = 8,
    DateTime? now,
  }) async {
    final current = now ?? DateTime.now();
    final insights = await insightsService.buildInsights(sortByEvLoss: true);
    if (insights.isEmpty) return [];

    await TrainingPackLibraryV2.instance.loadFromFolder();
    final library = TrainingPackLibraryV2.instance.packs;

    final history = await TrainingHistoryServiceV2.getHistory(limit: 50);
    final recentCutoff = current.subtract(const Duration(days: 3));
    final recentPackIds = <String>{
      for (final h in history)
        if (h.timestamp.isAfter(recentCutoff)) h.packId,
    };

    final clusterLoss = <MistakeTagCluster, double>{};
    final clusterTags = <MistakeTagCluster, Set<String>>{};
    for (final i in insights) {
      final c = clusterService.getClusterForTag(i.tag);
      clusterLoss.update(c, (v) => v + i.evLoss, ifAbsent: () => i.evLoss);
      (clusterTags[c] ??= <String>{}).add(i.tag.label.toLowerCase());
    }

    final clusters = clusterLoss.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final results = <TrainingPackTemplateV2>[];
    final usedSpots = <String>{};

    for (final entry in clusters.take(maxPacks)) {
      final tagSet = clusterTags[entry.key] ?? const <String>{};
      final candidates = <TrainingPackSpot>[];
      for (final p in library) {
        if (recentPackIds.contains(p.id)) continue;
        final packTags = p.tags.map((e) => e.toLowerCase()).toSet();
        if (!packTags.any(tagSet.contains)) continue;
        for (final s in p.spots) {
          final sTags = s.tags.map((e) => e.toLowerCase());
          if (sTags.any(tagSet.contains) && usedSpots.add(s.id)) {
            candidates.add(TrainingPackSpot.fromJson(s.toJson()));
          }
        }
      }
      if (candidates.isEmpty) continue;
      final selected = _selectSpots(candidates, maxSpots);
      final positions = {for (final s in selected) s.hand.position.name};
      final pack = TrainingPackTemplateV2(
        id: const Uuid().v4(),
        name: 'Booster: ${entry.key.label}',
        trainingType: TrainingType.pushFold,
        tags: [entry.key.label],
        spots: selected,
        spotCount: selected.length,
        created: current,
        gameType: GameType.tournament,
        positions: positions.toList(),
        meta: {'tag': entry.key.label, 'type': 'booster'},
      );
      results.add(pack);
    }

    return results;
  }

  List<TrainingPackSpot> _selectSpots(List<TrainingPackSpot> spots, int count) {
    if (spots.length <= count) return spots;
    final result = <TrainingPackSpot>[];
    final used = <String>{};
    for (final s in spots) {
      final key = '${s.hand.position.name}_${s.hand.board.length}';
      if (used.add(key)) {
        result.add(s);
        if (result.length >= count) break;
      }
    }
    if (result.length < count) {
      for (final s in spots) {
        if (!result.any((e) => e.id == s.id)) result.add(s);
        if (result.length >= count) break;
      }
    }
    return result.take(count).toList();
  }
}
