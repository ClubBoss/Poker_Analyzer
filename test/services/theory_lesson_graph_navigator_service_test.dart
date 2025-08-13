import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/theory_lesson_cluster.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/theory_lesson_graph_navigator_service.dart';
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

  test('navigation uses nextIds then cluster order', () async {
    final a = TheoryMiniLessonNode(
      id: 'a',
      title: 'A',
      content: '',
      nextIds: const ['b'],
    );
    final b = TheoryMiniLessonNode(id: 'b', title: 'B', content: '');
    final c = TheoryMiniLessonNode(id: 'c', title: 'C', content: '');
    final cluster = TheoryLessonCluster(lessons: [a, b, c], tags: const {});
    final nav = TheoryLessonGraphNavigatorService(
      library: _FakeLibrary([a, b, c]),
      cluster: cluster,
    );
    await nav.initialize();

    expect(nav.getNext('a')?.id, 'b');
    expect(nav.getNext('b')?.id, 'c');
    expect(nav.getNext('c'), isNull);

    expect(nav.getPrevious('c')?.id, 'b');
    expect(nav.getPrevious('b')?.id, 'a');
    expect(nav.getPrevious('a'), isNull);
  });

  test('getSiblings returns lessons from same cluster and tags', () async {
    final a = TheoryMiniLessonNode(
      id: 'a',
      title: 'A',
      content: '',
      tags: const ['x'],
    );
    final b = TheoryMiniLessonNode(
      id: 'b',
      title: 'B',
      content: '',
      tags: const ['y', 'x'],
    );
    final c = TheoryMiniLessonNode(
      id: 'c',
      title: 'C',
      content: '',
      tags: const ['y'],
    );
    final cluster = TheoryLessonCluster(lessons: [a, b, c], tags: const {});
    final nav = TheoryLessonGraphNavigatorService(
      library: _FakeLibrary([a, b, c]),
      cluster: cluster,
    );
    await nav.initialize();

    final sibs = nav.getSiblings('b').map((e) => e.id).toSet();
    expect(sibs, {'a', 'c'});
  });
}
