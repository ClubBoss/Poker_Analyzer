import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/mistake_insight.dart';
import 'package:poker_analyzer/models/mistake_tag.dart';
import 'package:poker_analyzer/services/mistake_cluster_analytics_service.dart';
import 'package:poker_analyzer/models/mistake_tag_cluster.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const service = MistakeClusterAnalyticsService();

  MistakeInsight insight(MistakeTag tag, int count, double loss) {
    return MistakeInsight(
      tag: tag,
      count: count,
      evLoss: loss,
      shortExplanation: '',
      examples: const [],
    );
  }

  test('compute aggregates insights by cluster', () {
    final insights = [
      insight(MistakeTag.overfoldBtn, 3, 1.5),
      insight(MistakeTag.looseCallBb, 2, 2.0),
      insight(MistakeTag.missedEvPush, 1, 0.5),
    ];

    final results = service.compute(insights);
    final blind = results
        .firstWhere((r) => r.cluster == MistakeTagCluster.looseCallBlind);
    expect(blind.totalMistakes, 2);
    expect(blind.totalEvLoss, 2.0);
    expect(blind.avgEvLoss, closeTo(1.0, 0.0001));
  });

  test('sortByEvLoss orders clusters', () {
    final clusters = [
      const ClusterAnalytics(
        cluster: MistakeTagCluster.aggressiveMistakes,
        totalMistakes: 1,
        totalEvLoss: 3,
        avgEvLoss: 3,
        tags: [],
      ),
      const ClusterAnalytics(
        cluster: MistakeTagCluster.missedEvOpportunities,
        totalMistakes: 2,
        totalEvLoss: 1,
        avgEvLoss: 0.5,
        tags: [],
      ),
    ];

    final sorted = service.sortByEvLoss(clusters);
    expect(sorted.first.cluster, MistakeTagCluster.aggressiveMistakes);
  });
}
