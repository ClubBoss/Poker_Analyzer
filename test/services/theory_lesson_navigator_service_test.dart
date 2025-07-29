import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/theory_lesson_cluster.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/theory_lesson_navigator_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('forward and backward navigation within cluster', () {
    final a = TheoryMiniLessonNode(
      id: 'a',
      title: 'A',
      content: '',
      nextIds: const ['b'],
    );
    final b = TheoryMiniLessonNode(
      id: 'b',
      title: 'B',
      content: '',
      nextIds: const ['c'],
    );
    final c = TheoryMiniLessonNode(
      id: 'c',
      title: 'C',
      content: '',
    );

    final cluster = TheoryLessonCluster(lessons: [a, b, c], tags: const {});
    final nav = TheoryLessonNavigatorService(cluster);

    expect(nav.getNext('a')?.id, 'b');
    expect(nav.getNext('b')?.id, 'c');
    expect(nav.getNext('c'), isNull);

    expect(nav.getPrevious('c')?.id, 'b');
    expect(nav.getPrevious('b')?.id, 'a');
    expect(nav.getPrevious('a'), isNull);
  });

  test('allNextIds and allPreviousIds filter unknown lessons', () {
    final a = TheoryMiniLessonNode(
      id: 'a',
      title: 'A',
      content: '',
      nextIds: const ['x', 'b', 'c'],
    );
    final b = TheoryMiniLessonNode(
      id: 'b',
      title: 'B',
      content: '',
    );
    final c = TheoryMiniLessonNode(
      id: 'c',
      title: 'C',
      content: '',
    );

    final cluster = TheoryLessonCluster(lessons: [a, b, c], tags: const {});
    final nav = TheoryLessonNavigatorService(cluster);

    expect(nav.getNext('a')?.id, 'b');
    expect(nav.getAllNextIds('a'), ['b', 'c']);
    expect(nav.getAllPreviousIds('b'), ['a']);
    expect(nav.getAllPreviousIds('c'), ['a']);
  });
}
