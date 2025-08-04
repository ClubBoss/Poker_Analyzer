import 'package:flutter_test/flutter_test.dart';

import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/models/inline_theory_linked_text.dart';
import 'package:poker_analyzer/services/inline_theory_linker_service.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/theory_mini_lesson_navigator.dart';

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
  List<TheoryMiniLessonNode> findByTags(List<String> tags) => [];

  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) => [];
}

class _FakeNavigator extends TheoryMiniLessonNavigator {
  String? openedTag;

  @override
  Future<void> openLessonByTag(String tag, [context]) async {
    openedTag = tag;
  }
}

void main() {
  test('links keywords in description and opens lesson', () {
    final library = _FakeLibrary([
      const TheoryMiniLessonNode(
        id: 'l1',
        title: 'CBet',
        content: '',
        tags: ['cbet'],
      ),
      const TheoryMiniLessonNode(
        id: 'l2',
        title: 'Probe',
        content: '',
        tags: ['probe'],
      ),
    ]);
    final navigator = _FakeNavigator();
    final service = InlineTheoryLinkerService(
      library: library,
      navigator: navigator,
    );
    final linked = service.link(
      'Study cbet and probe strategies.',
      contextTags: ['cbet', 'probe'],
    );
    expect(linked.chunks.length, 5);
    expect(linked.chunks[1].text.toLowerCase(), 'cbet');
    expect(linked.chunks[1].isLink, isTrue);
    linked.chunks[1].onTap?.call();
    expect(navigator.openedTag, 'cbet');
    linked.chunks[3].onTap?.call();
    expect(navigator.openedTag, 'probe');
  });

  test('respects context tags', () {
    final library = _FakeLibrary([
      const TheoryMiniLessonNode(
        id: 'l1',
        title: 'CBet',
        content: '',
        tags: ['cbet'],
      ),
      const TheoryMiniLessonNode(
        id: 'l2',
        title: 'Probe',
        content: '',
        tags: ['probe'],
      ),
    ]);
    final service = InlineTheoryLinkerService(library: library);
    final linked = service.link('cbet and probe', contextTags: ['cbet']);
    expect(linked.chunks.where((c) => c.isLink).length, 1);
    expect(linked.chunks[1].text.toLowerCase(), 'cbet');
  });
}
