import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/hand_data.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/theory_link_auto_injector.dart';

class _FakeLibrary implements MiniLessonLibraryService {
  final List<TheoryMiniLessonNode> lessons;
  _FakeLibrary(this.lessons);

  @override
  List<TheoryMiniLessonNode> get all => lessons;

  @override
  TheoryMiniLessonNode? getById(String id) =>
      lessons.firstWhere((e) => e.id == id, orElse: () => null);

  @override
  Future<void> loadAll() async {}

  @override
  Future<void> reload() async {}

  @override
  List<TheoryMiniLessonNode> findByTags(List<String> tags) => const [];

  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) => const [];

  @override
  List<String> linkedPacksFor(String lessonId) => const [];

  @override
  Future<bool> isLessonCompleted(String lessonId) async => false;

  @override
  Future<TheoryMiniLessonNode?> getNextLesson() async => null;

  @override
  TheoryMiniLessonNode? findLessonByTag(String tag) {
    for (final l in lessons) {
      if (l.tags.contains(tag)) return l;
    }
    return null;
  }
}

void main() {
  group('TheoryLinkAutoInjector', () {
    test('injects first matching theory id', () async {
      final spot = TrainingPackSpot(
        id: 's1',
        hand: HandData(),
        tags: ['a', 'b'],
      );
      final lessons = [
        TheoryMiniLessonNode(id: 'l1', title: 'A', content: '', tags: ['a']),
        TheoryMiniLessonNode(id: 'l2', title: 'B', content: '', tags: ['b']),
      ];
      final injector = TheoryLinkAutoInjector(library: _FakeLibrary(lessons));

      await injector.injectAll([spot]);

      expect(spot.theoryId, 'l1');
    });

    test('does not overwrite existing theory id', () async {
      final spot = TrainingPackSpot(
        id: 's1',
        hand: HandData(),
        tags: ['a'],
        theoryId: 'keep',
      );
      final lessons = [
        TheoryMiniLessonNode(id: 'l1', title: 'A', content: '', tags: ['a']),
      ];
      final injector = TheoryLinkAutoInjector(library: _FakeLibrary(lessons));

      await injector.injectAll([spot]);

      expect(spot.theoryId, 'keep');
    });
  });
}

