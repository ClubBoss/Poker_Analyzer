import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/theory_lesson_tag_clusterer.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';

class _FakeLibrary implements MiniLessonLibraryService {
  final List<TheoryMiniLessonNode> items;
  _FakeLibrary(this.items);

  @override
  List<TheoryMiniLessonNode> get all => items;

  @override
  TheoryMiniLessonNode? getById(String id) =>
      items.firstWhere((e) => e.id == id, orElse: () => null);

  @override
  Future<void> loadAll() async {}

  @override
  Future<void> reload() async {}

  @override
  List<TheoryMiniLessonNode> findByTags(List<String> tags) => const [];

  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) => const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('clusterLessons groups connected lessons', () async {
    final a = TheoryMiniLessonNode(
      id: 'a',
      title: 'A',
      content: '',
      tags: const ['preflop'],
      nextIds: const ['b'],
    );
    final b = TheoryMiniLessonNode(
      id: 'b',
      title: 'B',
      content: '',
      tags: const ['preflop'],
    );
    final c = TheoryMiniLessonNode(
      id: 'c',
      title: 'C',
      content: '',
      tags: const ['postflop'],
      nextIds: const ['d'],
    );
    final d = TheoryMiniLessonNode(
      id: 'd',
      title: 'D',
      content: '',
      tags: const ['postflop'],
    );

    final clusterer = TheoryLessonTagClusterer(
      library: _FakeLibrary([a, b, c, d]),
    );

    final clusters = await clusterer.clusterLessons();

    expect(clusters.length, 2);
    final ids =
        clusters.map((c) => c.lessons.map((e) => e.id).toSet()).toList();
    expect(
        ids,
        containsAll([
          {'a', 'b'},
          {'c', 'd'}
        ]));
  });
}
