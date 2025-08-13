import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/inline_theory_linker_cache.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';

class _FakeLibrary implements MiniLessonLibraryService {
  final List<TheoryMiniLessonNode> lessons;
  int loadCount = 0;
  _FakeLibrary(this.lessons);

  @override
  List<TheoryMiniLessonNode> get all => lessons;

  @override
  Future<void> loadAll() async {
    loadCount++;
  }

  @override
  Future<void> reload() async {}

  @override
  TheoryMiniLessonNode? getById(String id) =>
      lessons.firstWhere((l) => l.id == id, orElse: () => null);

  @override
  List<TheoryMiniLessonNode> findByTags(List<String> tags) {
    final set = tags.toSet();
    final seen = <String>{};
    final result = <TheoryMiniLessonNode>[];
    for (final l in lessons) {
      if (l.tags.any(set.contains)) {
        if (seen.add(l.id)) result.add(l);
      }
    }
    return result;
  }

  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) =>
      findByTags(tags.toList());

  @override
  List<String> linkedPacksFor(String lessonId) => const [];
}

void main() {
  test('ensureReady loads library only once', () async {
    final lib = _FakeLibrary(const [
      TheoryMiniLessonNode(
        id: 'l1',
        title: 'A',
        content: '',
        tags: ['tag'],
      ),
    ]);
    final cache = InlineTheoryLinkerCache(library: lib);
    await cache.ensureReady();
    await cache.ensureReady();
    expect(lib.loadCount, 1);
  });

  test('getMatchesForTags returns lessons after ready', () async {
    final lessons = const [
      TheoryMiniLessonNode(id: 'l1', title: 'A', content: '', tags: ['x']),
      TheoryMiniLessonNode(id: 'l2', title: 'B', content: '', tags: ['y']),
    ];
    final cache = InlineTheoryLinkerCache(library: _FakeLibrary(lessons));
    await cache.ensureReady();
    final matches = cache.getMatchesForTags(['y']);
    expect(matches.length, 1);
    expect(matches.first.id, 'l2');
  });
}
