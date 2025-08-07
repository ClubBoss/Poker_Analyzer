import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/services/theory_link_auto_injector_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TheoryLinkAutoInjectorService', () {
    test('injects linkedTheoryLessonId when tags match', () async {
      final spots = [
        TrainingPackSpot(id: 's1', tags: ['push']),
      ];
      final lessons = [
        const TheoryMiniLessonNode(
          id: 'l1',
          title: 'Push basics',
          content: '...',
          tags: ['push'],
        ),
      ];
      final service = TheoryLinkAutoInjectorService();
      final count = await service.injectLinks(spots, lessons: lessons);
      expect(count, 1);
      expect(spots.first.meta['linkedTheoryLessonId'], 'l1');
    });

    test('skips spots without matching lessons', () async {
      final spots = [
        TrainingPackSpot(id: 's2', tags: ['push']),
      ];
      final lessons = [
        const TheoryMiniLessonNode(
          id: 'l1',
          title: 'Fold basics',
          content: '...',
          tags: ['fold'],
        ),
      ];
      final service = TheoryLinkAutoInjectorService();
      final count = await service.injectLinks(spots, lessons: lessons);
      expect(count, 0);
      expect(spots.first.meta.containsKey('linkedTheoryLessonId'), false);
    });

    test('prefers lesson with more overlapping tags', () async {
      final spots = [
        TrainingPackSpot(id: 's3', tags: ['push', 'call']),
      ];
      final lessons = [
        const TheoryMiniLessonNode(
          id: 'l1',
          title: 'Push',
          content: '...',
          tags: ['push'],
        ),
        const TheoryMiniLessonNode(
          id: 'l2',
          title: 'Push and call',
          content: '...',
          tags: ['push', 'call'],
        ),
      ];
      final service = TheoryLinkAutoInjectorService();
      final count = await service.injectLinks(spots, lessons: lessons);
      expect(count, 1);
      expect(spots.first.meta['linkedTheoryLessonId'], 'l2');
    });
  });
}
