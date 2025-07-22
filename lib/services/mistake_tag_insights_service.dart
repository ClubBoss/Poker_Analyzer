import '../models/mistake_tag.dart';
import '../models/mistake_tag_cluster.dart';
import 'mistake_tag_cluster_service.dart';
import 'mistake_tag_history_service.dart';

class MistakeTagInsight {
  final MistakeTag tag;
  final int count;
  final double evLoss;
  final String packId;
  final String spotId;
  const MistakeTagInsight({
    required this.tag,
    required this.count,
    required this.evLoss,
    required this.packId,
    required this.spotId,
  });
}

class MistakeTagClusterInsight {
  final MistakeTagCluster cluster;
  final List<MistakeTagInsight> tagInsights;
  final int totalCount;
  final double totalEvLoss;
  const MistakeTagClusterInsight({
    required this.cluster,
    required this.tagInsights,
    required this.totalCount,
    required this.totalEvLoss,
  });
}

class MistakeTagInsightsService {
  final MistakeTagClusterService clusterService;
  const MistakeTagInsightsService({this.clusterService = const MistakeTagClusterService()});

  Future<List<MistakeTagClusterInsight>> computeInsights({int limit = 5}) async {
    final tagFreq = await MistakeTagHistoryService.getTagsByFrequency();
    final clusterData = <MistakeTagCluster, _ClusterData>{};
    for (final entry in tagFreq.entries) {
      final cluster = clusterService.getClusterForTag(entry.key);
      final mistakes = await MistakeTagHistoryService.getRecentMistakesByTag(entry.key, limit: 50);
      final evLoss = mistakes.fold<double>(0, (p, e) => p + e.evDiff.abs());
      final example = mistakes.isNotEmpty ? mistakes.first : null;
      final data = clusterData.putIfAbsent(cluster, () => _ClusterData());
      data.totalCount += entry.value;
      data.totalEvLoss += evLoss;
      data.tagInsights.add(MistakeTagInsight(
        tag: entry.key,
        count: entry.value,
        evLoss: evLoss,
        packId: example?.packId ?? '',
        spotId: example?.spotId ?? '',
      ));
    }
    final result = <MistakeTagClusterInsight>[];
    for (final entry in clusterData.entries) {
      entry.value.tagInsights.sort((a, b) => b.count.compareTo(a.count));
      result.add(MistakeTagClusterInsight(
        cluster: entry.key,
        tagInsights: entry.value.tagInsights.take(3).toList(),
        totalCount: entry.value.totalCount,
        totalEvLoss: entry.value.totalEvLoss,
      ));
    }
    result.sort((a, b) => b.totalCount.compareTo(a.totalCount));
    return result.take(limit).toList();
  }
}

class _ClusterData {
  int totalCount = 0;
  double totalEvLoss = 0;
  final List<MistakeTagInsight> tagInsights = [];
}

