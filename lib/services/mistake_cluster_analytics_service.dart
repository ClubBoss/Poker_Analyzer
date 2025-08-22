import '../models/mistake_insight.dart';
import '../models/mistake_tag.dart';
import '../models/mistake_tag_cluster.dart';
import 'mistake_tag_cluster_service.dart';

class ClusterAnalytics {
  final MistakeTagCluster cluster;
  final int totalMistakes;
  final double totalEvLoss;
  final double avgEvLoss;
  final List<MistakeTag> tags;

  ClusterAnalytics({
    required this.cluster,
    required this.totalMistakes,
    required this.totalEvLoss,
    required this.avgEvLoss,
    required this.tags,
  });
}

class MistakeClusterAnalyticsService {
  final MistakeTagClusterService clusterService;

  MistakeClusterAnalyticsService({
    this.clusterService = const MistakeTagClusterService(),
  });

  List<ClusterAnalytics> compute(List<MistakeInsight> insights) {
    final data = <MistakeTagCluster, _ClusterData>{};
    for (final i in insights) {
      final cluster = clusterService.getClusterForTag(i.tag);
      final d = data.putIfAbsent(cluster, () => _ClusterData());
      d.totalMistakes += i.count;
      d.totalEvLoss += i.evLoss;
      d.tags.add(i.tag);
    }

    final results = <ClusterAnalytics>[];
    data.forEach((cluster, d) {
      final avg = d.totalMistakes > 0 ? d.totalEvLoss / d.totalMistakes : 0.0;
      results.add(
        ClusterAnalytics(
          cluster: cluster,
          totalMistakes: d.totalMistakes,
          totalEvLoss: d.totalEvLoss,
          avgEvLoss: avg,
          tags: d.tags.toList(),
        ),
      );
    });

    results.sort((a, b) => b.totalMistakes.compareTo(a.totalMistakes));
    return results;
  }

  List<ClusterAnalytics> sortByMistakes(
    List<ClusterAnalytics> list, {
    bool descending = true,
  }) {
    final result = List<ClusterAnalytics>.from(list);
    result.sort(
      (a, b) => descending
          ? b.totalMistakes.compareTo(a.totalMistakes)
          : a.totalMistakes.compareTo(b.totalMistakes),
    );
    return result;
  }

  List<ClusterAnalytics> sortByEvLoss(
    List<ClusterAnalytics> list, {
    bool descending = true,
  }) {
    final result = List<ClusterAnalytics>.from(list);
    result.sort(
      (a, b) => descending
          ? b.totalEvLoss.compareTo(a.totalEvLoss)
          : a.totalEvLoss.compareTo(b.totalEvLoss),
    );
    return result;
  }
}

class _ClusterData {
  int totalMistakes = 0;
  double totalEvLoss = 0;
  final Set<MistakeTag> tags = {};
}
