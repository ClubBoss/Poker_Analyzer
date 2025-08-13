import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/auto_skill_gap_clusterer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('clusters overlapping weak tags', () {
    final clusterer = AutoSkillGapClusterer(
      linkPercentage: 0.5,
      maxClusterSize: 3,
    );
    final weak = ['a', 'b', 'c', 'd'];
    final spotTags = {
      's1': ['a', 'b'],
      's2': ['a', 'b'],
      's3': ['a', 'c'],
      's4': ['d'],
    };
    final clusters = clusterer.clusterWeakTags(
      weakTags: weak,
      spotTags: spotTags,
    );
    expect(clusters.length, 2);
    final main = clusters.firstWhere((c) => c.tags.contains('a'));
    expect(main.tags, containsAll(['a', 'b', 'c']));
    expect(
        clusters.any((c) => c.tags.length == 1 && c.tags.first == 'd'), isTrue);
  });
}
