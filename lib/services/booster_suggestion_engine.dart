import '../models/mistake_insight.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/training_history_entry_v2.dart';
import '../core/training/library/training_pack_library_v2.dart';
import 'mistake_tag_insights_service.dart';
import 'mistake_tag_cluster_service.dart';
import 'training_pack_stats_service_v2.dart';
import 'training_history_service_v2.dart';

class BoosterSuggestionEngine {
  const BoosterSuggestionEngine();

  /// Returns the id of the best booster pack to recommend.
  ///
  /// [library] and other optional parameters are mainly for testing.
  Future<String?> suggestBooster({
    List<TrainingPackTemplateV2>? library,
    Map<String, double>? improvement,
    List<MistakeInsight>? insights,
    List<TrainingHistoryEntryV2>? history,
    DateTime? now,
  }) async {
    final current = now ?? DateTime.now();
    final improvementMap = improvement ??
        await TrainingPackStatsServiceV2.improvementByTag();
    insights ??= await const MistakeTagInsightsService()
        .buildInsights(sortByEvLoss: true);
    history ??= await TrainingHistoryServiceV2.getHistory(limit: 50);

    await TrainingPackLibraryV2.instance.loadFromFolder();
    final packs = library ?? TrainingPackLibraryV2.instance.packs;

    final recentCutoff = current.subtract(const Duration(days: 3));
    final recentPackIds = <String>{
      for (final h in history)
        if (h.timestamp.isAfter(recentCutoff)) h.packId
    };

    final boosterMap = <String, TrainingPackTemplateV2>{};
    for (final p in packs) {
      if (p.meta['type'] == 'booster') {
        final tag = p.meta['tag']?.toString().toLowerCase();
        if (tag != null && tag.isNotEmpty) {
          boosterMap[tag] = p;
        }
      }
    }
    if (boosterMap.isEmpty || insights.isEmpty) return null;

    const threshold = 0.05;
    const clusterService = MistakeTagClusterService();

    String? bestId;
    for (final i in insights) {
      final cluster = clusterService.getClusterForTag(i.tag);
      final key = cluster.label.toLowerCase();
      final imp = improvementMap[key] ?? 1.0;
      if (imp <= threshold) {
        final pack = boosterMap[key];
        if (pack != null && !recentPackIds.contains(pack.id)) {
          bestId = pack.id;
          break;
        }
      }
    }

    if (bestId != null) return bestId;

    for (final i in insights) {
      final cluster = clusterService.getClusterForTag(i.tag);
      final key = cluster.label.toLowerCase();
      final pack = boosterMap[key];
      if (pack != null && !recentPackIds.contains(pack.id)) {
        return pack.id;
      }
    }

    return null;
  }
}
