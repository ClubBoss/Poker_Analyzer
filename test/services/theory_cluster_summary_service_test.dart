import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/theory_lesson_cluster.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/theory_cluster_summary_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generateSummary computes size, entry points and shared tags', () {
    final a = TheoryMiniLessonNode(
      id: 'a',
      title: 'A',
      content: '',
      tags: const ['preflop'],
      nextIds: const ['b'],
    );
    final b = TheoryMiniLessonNode(
      id: 'b',
      title: 'B',
      content: '',
      tags: const ['preflop', 'icm'],
      nextIds: const [],
    );
    final c = TheoryMiniLessonNode(
      id: 'c',
      title: 'C',
      content: '',
      tags: const ['icm'],
      nextIds: const ['b'],
    );

    final cluster =
        TheoryLessonCluster(lessons: [a, b, c], tags: const {'preflop', 'icm'});
    final service = TheoryClusterSummaryService();

    final summary = service.generateSummary(cluster);

    expect(summary.size, 3);
    expect(summary.entryPointIds.toSet(), {'a', 'c'});
    expect(summary.sharedTags, {'preflop', 'icm'});
  });

  test('summarize returns summary per cluster', () {
    final cluster1 = TheoryLessonCluster(lessons: [
      TheoryMiniLessonNode(
          id: 'x',
          title: 'X',
          content: '',
          nextIds: const [],
          tags: const ['a']),
    ], tags: const {
      'a'
    });
    final cluster2 = TheoryLessonCluster(lessons: [
      TheoryMiniLessonNode(
          id: 'y',
          title: 'Y',
          content: '',
          nextIds: const [],
          tags: const ['b']),
    ], tags: const {
      'b'
    });

    final service = TheoryClusterSummaryService();
    final result = service.summarize([cluster1, cluster2]);

    expect(result.length, 2);
  });
}
