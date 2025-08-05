import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/theory_lesson_meta_tag_extractor_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TheoryLessonMetaTagExtractorService', () {
    const service = TheoryLessonMetaTagExtractorService();

    test('extracts metadata from tags', () {
      const lesson = TheoryMiniLessonNode(
        id: 'l1',
        title: 'BTN vs BB, Flop CBet',
        content: '',
        tags: ['BTN', 'vs BB', 'Flop', 'Dry'],
      );

      final meta = service.extract(lesson);

      expect(meta.position, 'BTN');
      expect(meta.villainPosition, 'BB');
      expect(meta.street, 'Flop');
      expect(meta.boardTexture, 'Dry');
    });

    test('extracts metadata from title when tags missing', () {
      const lesson = TheoryMiniLessonNode(
        id: 'l2',
        title: 'SB vs BTN on Paired Turn',
        content: '',
        tags: [],
      );

      final meta = service.extract(lesson);

      expect(meta.position, isNull);
      expect(meta.villainPosition, 'BTN');
      expect(meta.street, 'Turn');
      expect(meta.boardTexture, 'Paired');
    });

    test('returns nulls when no matches found', () {
      const lesson = TheoryMiniLessonNode(
        id: 'l3',
        title: 'Generic lesson',
        content: '',
        tags: ['misc'],
      );

      final meta = service.extract(lesson);

      expect(meta.position, isNull);
      expect(meta.villainPosition, isNull);
      expect(meta.street, isNull);
      expect(meta.boardTexture, isNull);
    });
  });
}
