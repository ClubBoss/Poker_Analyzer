import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/theory_lesson_cluster.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/theory_mini_map_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('build returns nodes and edges for cluster', () {
    final a = TheoryMiniLessonNode(
      id: 'a',
      title: 'A',
      content: '',
      tags: const [],
      nextIds: const ['b'],
    );
    final b = TheoryMiniLessonNode(
      id: 'b',
      title: 'B',
      content: '',
      tags: const [],
      nextIds: const ['c'],
    );
    final c = TheoryMiniLessonNode(
      id: 'c',
      title: 'C',
      content: '',
      tags: const [],
      nextIds: const [],
    );
    final cluster = TheoryLessonCluster(lessons: [a, b, c], tags: const {});
    final renderer = TheoryMiniMapRenderer(cluster);

    final graph = renderer.build('b');

    expect(graph.nodes.length, 3);
    expect(graph.edges.length, 2);
    final current = graph.nodes.firstWhere((n) => n.id == 'b');
    expect(current.isCurrent, isTrue);
  });
}
