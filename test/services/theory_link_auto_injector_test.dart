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
}

void main() {
  group('TheoryLinkAutoInjector', () {
    test('injects lessons using spot and board tags', () async {
      final spot = TrainingPackSpot(
        id: 's1',
        hand: HandData(),
        tags: ['openSB'],
        board: ['Ah', 'Ad', '7c'],
      );
      final lessons = [
        TheoryMiniLessonNode(
          id: 'l1',
          title: 'SB',
          content: '',
          tags: ['openSB'],
        ),
        TheoryMiniLessonNode(
          id: 'l2',
          title: 'Paired Boards',
          content: '',
          tags: ['paired'],
        ),
      ];
      final injector = TheoryLinkAutoInjector(library: _FakeLibrary(lessons));

      await injector.injectAll([spot]);

      expect(spot.meta['linkedTheoryLessonIds'], ['l1', 'l2']);
    });

    test('respects max link limit', () async {
      final spot = TrainingPackSpot(id: 's1', hand: HandData(), tags: ['t']);
      final lessons = [
        TheoryMiniLessonNode(id: 'l1', title: 'A', content: '', tags: ['t']),
        TheoryMiniLessonNode(id: 'l2', title: 'B', content: '', tags: ['t']),
        TheoryMiniLessonNode(id: 'l3', title: 'C', content: '', tags: ['t']),
      ];
      final injector = TheoryLinkAutoInjector(
        maxLinks: 2,
        library: _FakeLibrary(lessons),
      );

      await injector.injectAll([spot]);

      final ids = spot.meta['linkedTheoryLessonIds'] as List<String>;
      expect(ids.length, 2);
    });

    test('matches lessons using board textures alone', () async {
      final spot = TrainingPackSpot(
        id: 's1',
        hand: HandData(),
        board: ['Ah', 'Ad', '7c'],
      );
      final lessons = [
        TheoryMiniLessonNode(
          id: 'l1',
          title: 'Paired Boards',
          content: '',
          tags: ['paired'],
        ),
      ];
      final injector = TheoryLinkAutoInjector(library: _FakeLibrary(lessons));

      await injector.injectAll([spot]);

      expect(spot.meta['linkedTheoryLessonIds'], ['l1']);
    });
  });
}

