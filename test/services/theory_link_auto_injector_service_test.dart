import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/hand_data.dart';
import 'package:poker_analyzer/models/skill_tag_coverage_report.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/models/training_pack_model.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/services/inline_theory_linker.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/theory_link_auto_injector_service.dart';
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
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) =>
      findByTags(tags.toList());
}

class _FakeNavigator extends TheoryMiniLessonNavigator {
  String? openedTag;

  @override
  Future<void> openLessonByTag(String tag, [context]) async {
    openedTag = tag;
  }
}

void main() {
  group('TheoryLinkAutoInjectorService', () {
    test('injects link for underrepresented tag', () {
      final library = _FakeLibrary({
        'cbet': const TheoryMiniLessonNode(
            id: '1', title: 'CBet', content: '', tags: ['cbet']),
      });
      final navigator = _FakeNavigator();
      final service = TheoryLinkAutoInjectorService(
        library: library,
        navigator: navigator,
      );
      final spot = TrainingPackSpot(id: 's1', hand: HandData(), tags: ['cbet']);
      final pack = TrainingPackModel(id: 'p1', title: 'Pack', spots: [spot]);

      service.injectLinks(
        const SkillTagCoverageReport(
          tagCounts: {},
          underrepresentedTags: ['cbet'],
        ),
        [pack],
      );

      expect(spot.theoryLink?.title, 'CBet');
      spot.theoryLink?.onTap();
      expect(navigator.openedTag, 'cbet');
    });

    test('does not override existing theoryLink', () {
      final library = _FakeLibrary({
        'cbet': const TheoryMiniLessonNode(
            id: '1', title: 'CBet', content: '', tags: ['cbet']),
      });
      final navigator = _FakeNavigator();
      final service = TheoryLinkAutoInjectorService(
        library: library,
        navigator: navigator,
      );
      final spot = TrainingPackSpot(
        id: 's1',
        hand: HandData(),
        tags: ['cbet'],
      )..theoryLink = InlineTheoryLink(title: 'Existing', onTap: () {});
      final pack = TrainingPackModel(id: 'p1', title: 'Pack', spots: [spot]);

      service.injectLinks(
        const SkillTagCoverageReport(
          tagCounts: {},
          underrepresentedTags: ['cbet'],
        ),
        [pack],
      );

      expect(spot.theoryLink?.title, 'Existing');
      expect(navigator.openedTag, isNull);
    });

    test('skips when no lesson found', () {
      final library = _FakeLibrary({});
      final navigator = _FakeNavigator();
      final service = TheoryLinkAutoInjectorService(
        library: library,
        navigator: navigator,
      );
      final spot = TrainingPackSpot(id: 's1', hand: HandData(), tags: ['cbet']);
      final pack = TrainingPackModel(id: 'p1', title: 'Pack', spots: [spot]);

      service.injectLinks(
        const SkillTagCoverageReport(
          tagCounts: {},
          underrepresentedTags: ['cbet'],
        ),
        [pack],
      );

      expect(spot.theoryLink, isNull);
    });
  });
}
