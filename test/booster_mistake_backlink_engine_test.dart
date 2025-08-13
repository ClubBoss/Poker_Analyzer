import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/booster_mistake_backlink_engine.dart';
import 'package:poker_analyzer/models/weak_cluster_info.dart';
import 'package:poker_analyzer/models/theory_cluster_summary.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

WeakClusterInfo _cluster(String id, Set<String> tags) => WeakClusterInfo(
      cluster: TheoryClusterSummary(
        size: 1,
        entryPointIds: [id],
        sharedTags: tags,
      ),
      coverage: 1.0,
      score: 1.0,
    );

TrainingPackTemplateV2 _booster(String tag, {String? clusterId}) =>
    TrainingPackTemplateV2(
      id: 'b',
      name: 'b',
      trainingType: TrainingType.theory,
      tags: [tag],
      spots: const [],
      spotCount: 0,
      meta: clusterId != null ? {'generatedFromClusterId': clusterId} : {},
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('links booster by cluster id', () {
    final clusters = [
      _cluster('c1', {'push'})
    ];
    final booster = _booster('push', clusterId: 'c1');

    const engine = BoosterMistakeBacklinkEngine();
    final res = engine.link(booster, clusters);

    expect(res.sourceCluster, isNotNull);
    expect(res.sourceCluster!.entryPointIds.first, 'c1');
    expect(res.matchingTags, contains('push'));
  });

  test('links booster by tag overlap', () {
    final clusters = [
      _cluster('c1', {'push'}),
      _cluster('c2', {'call'})
    ];
    final booster = _booster('call');

    const engine = BoosterMistakeBacklinkEngine();
    final res = engine.link(booster, clusters);

    expect(res.sourceCluster, isNotNull);
    expect(res.sourceCluster!.entryPointIds.first, 'c2');
    expect(res.matchingTags, contains('call'));
  });
}
