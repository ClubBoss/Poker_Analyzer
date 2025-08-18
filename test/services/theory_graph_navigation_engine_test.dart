import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/theory_graph_navigation_engine.dart';
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

  test('basic navigation and restart', () async {
    final a = TheoryMiniLessonNode(
      id: 'a',
      title: 'A',
      content: '',
      nextIds: const ['b'],
    );
    final b = TheoryMiniLessonNode(
      id: 'b',
      title: 'B',
      content: '',
      tags: const ['milestone'],
      nextIds: const ['c'],
    );
    final c = TheoryMiniLessonNode(id: 'c', title: 'C', content: '');
    final engine = TheoryGraphNavigationEngine(
      library: _FakeLibrary([a, b, c]),
    );
    await engine.initialize();

    expect(engine.getNext('a')?.id, 'b');
    expect(engine.getPrevious('c')?.id, 'b');
    expect(engine.getRestartPoint('c')?.id, 'b');
    expect(engine.getRestartPoint('a')?.id, 'a');
  });

  test('cycles terminate at last node', () async {
    final root = TheoryMiniLessonNode(
      id: 'root',
      title: 'R',
      content: '',
      nextIds: const ['x'],
    );
    final x = TheoryMiniLessonNode(
      id: 'x',
      title: 'X',
      content: '',
      nextIds: const ['y'],
    );
    final y = TheoryMiniLessonNode(
      id: 'y',
      title: 'Y',
      content: '',
      nextIds: const ['x'],
    );
    final engine = TheoryGraphNavigationEngine(
      library: _FakeLibrary([root, x, y]),
    );
    await engine.initialize();

    expect(engine.getNext('x')?.id, 'y');
    expect(engine.getNext('y'), isNull);
  });
}
