import 'package:flutter_test/flutter_test.dart';

import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/hand_data.dart';
import 'package:poker_analyzer/services/auto_spot_theory_injector_service.dart';
import 'package:poker_analyzer/services/inline_theory_linker.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/theory_mini_lesson_navigator.dart';

class _FakeLibrary implements MiniLessonLibraryService {
  final Map<String, TheoryMiniLessonNode> byTag;
  _FakeLibrary(this.byTag);

  @override
  List<TheoryMiniLessonNode> get all => byTag.values.toList();

  @override
  TheoryMiniLessonNode? getById(String id) =>
      all.firstWhere((e) => e.id == id, orElse: () => null);

  @override
  Future<void> loadAll() async {}

  @override
  Future<void> reload() async {}

  @override
  List<TheoryMiniLessonNode> findByTags(List<String> tags) => [
        for (final t in tags)
          if (byTag[t] != null) byTag[t]!,
      ];

  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) => [
        for (final t in tags)
          if (byTag[t] != null) byTag[t]!,
      ];
}

class _FakeNavigator extends TheoryMiniLessonNavigator {
  String? openedTag;

  @override
  Future<void> openLessonByTag(String tag, [context]) async {
    openedTag = tag;
  }
}

void main() {
  group('AutoSpotTheoryInjectorService', () {
    test('injects matching theory link', () {
      final library = _FakeLibrary({
        'cbet': const TheoryMiniLessonNode(
            id: '1', title: 'CBet', content: '', tags: ['cbet']),
      });
      final nav = _FakeNavigator();
      final linker = InlineTheoryLinker(library: library, navigator: nav);
      final service = AutoSpotTheoryInjectorService(linker: linker);
      final spot = TrainingPackSpot(id: 's1', hand: HandData(), tags: ['cbet']);

      service.inject(spot);

      expect(spot.theoryLink?.title, 'CBet');
      spot.theoryLink?.onTap();
      expect(nav.openedTag, 'cbet');
    });

    test('leaves theoryLink null when no match', () {
      final library = _FakeLibrary({});
      final service = AutoSpotTheoryInjectorService(
          linker: InlineTheoryLinker(
              library: library, navigator: _FakeNavigator()));
      final spot = TrainingPackSpot(id: 's1', hand: HandData(), tags: ['cbet']);

      service.inject(spot);

      expect(spot.theoryLink, isNull);
    });
  });
}
