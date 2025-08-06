import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/theory_lesson_cluster.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/utils/theory_cluster_id_hasher.dart';

void main() {
  test('produces stable id regardless of lesson order', () {
    final l1 = TheoryMiniLessonNode(id: 'a', title: 'A', content: '');
    final l2 = TheoryMiniLessonNode(id: 'b', title: 'B', content: '');
    final c1 = TheoryLessonCluster(lessons: [l1, l2], tags: {});
    final c2 = TheoryLessonCluster(lessons: [l2, l1], tags: {});

    final id1 = TheoryClusterIdHasher.hash(c1);
    final id2 = TheoryClusterIdHasher.hash(c2);
    expect(id1, id2);
  });

  test('produces different ids for different clusters', () {
    final l1 = TheoryMiniLessonNode(id: 'a', title: 'A', content: '');
    final l2 = TheoryMiniLessonNode(id: 'b', title: 'B', content: '');
    final l3 = TheoryMiniLessonNode(id: 'c', title: 'C', content: '');
    final c1 = TheoryLessonCluster(lessons: [l1, l2], tags: {});
    final c2 = TheoryLessonCluster(lessons: [l1, l3], tags: {});

    final id1 = TheoryClusterIdHasher.hash(c1);
    final id2 = TheoryClusterIdHasher.hash(c2);
    expect(id1, isNot(id2));
  });
}
