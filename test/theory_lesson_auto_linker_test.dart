import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/theory_lesson_auto_linker.dart';

void main() {
  test('suggestLinks ranks overlapping lessons by score', () {
    final l1 = TheoryMiniLessonNode(
      id: 'l1',
      title: 'L1',
      content: 'short text',
      tags: const ['a'],
    );
    final l2 = TheoryMiniLessonNode(
      id: 'l2',
      title: 'L2',
      content: 'longer content with more words',
      tags: const ['a', 'b'],
    );
    final l3 = TheoryMiniLessonNode(
      id: 'l3',
      title: 'L3',
      content: 'medium content here',
      tags: const ['a'],
    );
    final linker = const TheoryLessonAutoLinker();
    final map = linker.suggestLinks([l1, l2, l3]);
    expect(map['l1'], isNotNull);
    expect(map['l1']!.first, 'l2');
    expect(map.containsKey('l2'), isFalse);
  });
}
