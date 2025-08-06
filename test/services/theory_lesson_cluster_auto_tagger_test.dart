import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/theory_lesson_cluster.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/theory_lesson_cluster_auto_tagger.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('tagClusters assigns top tags to clusters', () {
    final a = TheoryMiniLessonNode(
      id: 'a',
      title: 'A',
      content: '',
      tags: const ['push', 'preflop'],
    );
    final b = TheoryMiniLessonNode(
      id: 'b',
      title: 'B',
      content: '',
      tags: const ['push', 'call'],
    );
    final c = TheoryMiniLessonNode(
      id: 'c',
      title: 'C',
      content: '',
      tags: const ['push', 'call'],
    );

    final cluster = TheoryLessonCluster(
      lessons: [a, b, c],
      tags: const {'push', 'call', 'preflop'},
    );

    TheoryLessonClusterAutoTagger().tagClusters([cluster]);

    expect(cluster.autoTags, ['push', 'call', 'preflop']);
  });
}
