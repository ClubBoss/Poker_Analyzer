import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/theory_mini_lesson_factory_service.dart';
import 'package:poker_analyzer/services/theory_lesson_meta_tag_extractor_service.dart';
import 'package:poker_analyzer/services/theory_mini_lesson_content_template_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generates content automatically when autoContent is true', () {
    final factory = TheoryMiniLessonFactoryService(
      extractor: const TheoryLessonMetaTagExtractorService(),
      templateService: const TheoryMiniLessonContentTemplateService(
        templateMap: {'BTN vs BB, Flop CBet': 'auto text'},
      ),
    );

    final yaml = {
      'id': 'l1',
      'title': 'BTN vs BB, Flop CBet',
      'content': '',
      'tags': ['BTN', 'vs BB', 'Flop', 'CBet'],
      'autoContent': true,
    };

    final node = factory.fromYaml(Map<String, dynamic>.from(yaml));
    expect(node.content, 'auto text');
    expect(node.autoContent, isTrue);
  });
}
