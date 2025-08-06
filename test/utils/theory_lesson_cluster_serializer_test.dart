import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/theory_lesson_cluster.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/utils/theory_cluster_id_hasher.dart';
import 'package:poker_analyzer/utils/theory_lesson_cluster_serializer.dart';

void main() {
  test('serializes and deserializes cluster', () {
    final l1 = TheoryMiniLessonNode(id: 'a', title: 'A', content: '', tags: ['t']);
    final l2 = TheoryMiniLessonNode(id: 'b', title: 'B', content: '', tags: ['t']);
    final cluster = TheoryLessonCluster(
      lessons: [l1, l2],
      tags: {'t'},
      autoTags: ['x'],
    );

    final serializer = TheoryLessonClusterSerializer();
    final json = serializer.toJson(cluster);
    final (decoded, cid) = serializer.fromJson(json);

    expect(decoded.lessons.length, 2);
    expect(decoded.sharedTags, {'t'});
    expect(decoded.autoTags, ['x']);
    expect(cid, json['clusterId']);
  });

  test('computes clusterId when missing', () {
    final lesson = TheoryMiniLessonNode(id: 'a', title: 'A', content: '');
    final cluster = TheoryLessonCluster(lessons: [lesson], tags: {});
    final serializer = TheoryLessonClusterSerializer();
    final map = {
      'lessons': [lesson.toJson()],
      'sharedTags': [],
    };
    final (_, cid) = serializer.fromJson(map);
    expect(cid, TheoryClusterIdHasher.hash(cluster));
  });
}
