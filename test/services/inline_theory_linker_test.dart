import 'package:flutter_test/flutter_test.dart';

import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
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
  test('returns prioritized link and triggers navigator', () {
    final library = _FakeLibrary({
      'cbet': const TheoryMiniLessonNode(
        id: '1',
        title: 'CBet',
        content: '',
        tags: ['cbet'],
      ),
      'probe': const TheoryMiniLessonNode(
        id: '2',
        title: 'Probe',
        content: '',
        tags: ['probe'],
      ),
    });
    final nav = _FakeNavigator();
    final linker = InlineTheoryLinker(library: library, navigator: nav);
    final link = linker.getLink(['probe', 'cbet']);
    expect(link?.title, 'CBet');
    link?.onTap();
    expect(nav.openedTag, 'cbet');
  });

  test('returns null when no lesson matches', () {
    final library = _FakeLibrary({});
    final linker = InlineTheoryLinker(
      library: library,
      navigator: _FakeNavigator(),
    );
    final link = linker.getLink(['cbet']);
    expect(link, isNull);
  });
}
