import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/lesson_search_engine.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';

void main() {
  test('fuzzy search by title, tags and content', () {
    const l1 = TheoryMiniLessonNode(
      id: 'l1',
      title: 'Bubble Play',
      content: 'Fold near the bubble.',
      tags: ['icm'],
    );
    const l2 = TheoryMiniLessonNode(
      id: 'l2',
      title: 'Iso Raise',
      content: 'Isolate limpers aggressively.',
      tags: ['iso'],
    );

    final engine = LessonSearchEngine(library: [l1, l2]);
    final res1 = engine.search('bubble');
    expect(res1.first, l1);
    final res2 = engine.search('limper');
    expect(res2.first, l2);
  });
}
