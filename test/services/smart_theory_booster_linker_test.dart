import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/models/theory_lesson_cluster.dart';
import 'package:poker_analyzer/services/smart_theory_booster_linker.dart';
import 'package:poker_analyzer/services/theory_lesson_tag_clusterer.dart';
import 'package:poker_analyzer/services/theory_cluster_summary_service.dart';

class _StubClusterer extends TheoryLessonTagClusterer {
  final List<TheoryLessonCluster> clusters;
  _StubClusterer(this.clusters);
  @override
  Future<List<TheoryLessonCluster>> clusterLessons() async => clusters;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('linkForLesson returns deep link to containing cluster', () async {
    const l1 = TheoryMiniLessonNode(id: 'a', title: 'A', content: '', nextIds: ['b']);
    const l2 = TheoryMiniLessonNode(id: 'b', title: 'B', content: '');
    final cluster = TheoryLessonCluster(lessons: [l1, l2], tags: {'preflop'});

    final linker = SmartTheoryBoosterLinker(
      clusterer: _StubClusterer([cluster]),
      summaryService: TheoryClusterSummaryService(),
    );

    final link = await linker.linkForLesson('b');
    expect(link, '/theory/cluster?clusterId=a');
  });

  test('linkForTags picks cluster with overlapping tags', () async {
    final c1 = TheoryLessonCluster(
      lessons: [TheoryMiniLessonNode(id: 'l1', title: 'L1', content: '')],
      tags: {'push'},
    );
    final c2 = TheoryLessonCluster(
      lessons: [TheoryMiniLessonNode(id: 'l2', title: 'L2', content: '')],
      tags: {'call'},
    );

    final linker = SmartTheoryBoosterLinker(
      clusterer: _StubClusterer([c1, c2]),
      summaryService: TheoryClusterSummaryService(),
    );

    final link = await linker.linkForTags(['call']);
    expect(link, '/theory/cluster?clusterId=l2');
  });
}

