import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/theory_mini_lesson_content_template_service.dart';
import 'package:poker_analyzer/constants/theory_lesson_template_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fills content for single node', () {
    final service = TheoryMiniLessonContentTemplateService(templateMap: {
      'BTN vs BB, Flop CBet': 'template text',
    });
    final node = TheoryMiniLessonNode(
      id: 'l1',
      title: 'T',
      content: '',
      tags: ['BTN vs BB', 'Flop CBet'],
    );
    final result = service.withGeneratedContent(node);
    expect(result.content, 'template text');
  });

  test('fills content for list', () {
    final service = TheoryMiniLessonContentTemplateService(templateMap: {
      'BTN vs BB, Flop CBet': 'template text',
    });
    final lessons = [
      TheoryMiniLessonNode(
        id: 'l1',
        title: 'T1',
        content: '',
        tags: ['BTN vs BB', 'Flop CBet'],
      ),
      TheoryMiniLessonNode(
        id: 'l2',
        title: 'T2',
        content: '',
        tags: ['BTN vs BB', 'Flop CBet'],
      ),
    ];
    final result = service.withGeneratedContentForAll(lessons);
    expect(result.every((l) => l.content == 'template text'), isTrue);
  });

  test('uses centralized template map by default', () {
    final service = TheoryMiniLessonContentTemplateService();
    final node = TheoryMiniLessonNode(
      id: 'l1',
      title: 'T',
      content: '',
      tags: ['BTN vs BB', 'Flop CBet'],
    );
    final result = service.withGeneratedContent(node);
    expect(result.content, theoryLessonTemplateMap['BTN vs BB, Flop CBet']);
  });
}

