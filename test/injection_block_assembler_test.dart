import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/injection_block_assembler.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';

void main() {
  test('build creates formatted block', () {
    const lesson = TheoryMiniLessonNode(
      id: 'l1',
      title: 'Title',
      content: 'Paragraph one.\n\nParagraph two.',
      tags: [],
      nextIds: [],
    );
    final assembler = InjectionBlockAssembler();
    final block = assembler.build(lesson, 's1');
    expect(block.header, 'Краткий разбор: Title');
    expect(block.content, 'Paragraph one.');
    expect(block.ctaLabel, 'Читать подробнее');
    expect(block.lessonId, 'l1');
    expect(block.injectedInStageId, 's1');
  });
}
