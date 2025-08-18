import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/cluster_review_booster_builder.dart';
import 'package:poker_analyzer/models/weak_cluster_info.dart';
import 'package:poker_analyzer/models/theory_cluster_summary.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('build creates booster pack from cluster', () {
    final cluster = TheoryClusterSummary(
      size: 3,
      entryPointIds: const ['c1'],
      sharedTags: const {'push', 'call'},
    );
    final weak = WeakClusterInfo(cluster: cluster, coverage: 0.5, score: 1.0);

    final lessons = <String, TheoryMiniLessonNode>{
      'l1': const TheoryMiniLessonNode(
        id: 'l1',
        title: 'L1',
        content: '',
        tags: ['push'],
      ),
      'l2': const TheoryMiniLessonNode(
        id: 'l2',
        title: 'L2',
        content: '',
        tags: ['push'],
      ),
      'l3': const TheoryMiniLessonNode(
        id: 'l3',
        title: 'L3',
        content: '',
        tags: ['call'],
      ),
      'l4': const TheoryMiniLessonNode(
        id: 'l4',
        title: 'L4',
        content: '',
        tags: ['fold'],
      ),
    };

    final builder = ClusterReviewBoosterBuilder();
    final tpl = builder.build(
      weakCluster: weak,
      allLessons: lessons,
      completedLessons: const {'l1'},
      tagAccuracy: const {'push': 0.6},
    );

    expect(tpl.name.startsWith('Review:'), isTrue);
    expect(tpl.tags, contains('push'));
    expect(tpl.spots.length, 3);
    expect(tpl.spots.every((s) => s.type == 'theory'), isTrue);
    expect(tpl.meta['source'], 'booster');
    expect(tpl.meta['generatedFromClusterId'], 'c1');
  });
}
