import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/theory_lesson_graph_exporter.dart';
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
  List<TheoryMiniLessonNode> findByTags(List<String> tags) {
    final result = <TheoryMiniLessonNode>[];
    for (final t in tags) {
      result.addAll(items.where((e) => e.tags.contains(t)));
    }
    return result;
  }

  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) =>
      findByTags(tags.toList());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generateDotGraph outputs nodes and edges', () async {
    final lesson1 = TheoryMiniLessonNode(
      id: 'l1',
      title: 'One',
      content: 'c1',
      tags: const ['a'],
      nextIds: const ['l2'],
    );
    final lesson2 = TheoryMiniLessonNode(
      id: 'l2',
      title: 'Two',
      content: 'c2',
      tags: const ['b'],
    );

    final exporter = TheoryLessonGraphExporter(
      library: _FakeLibrary([lesson1, lesson2]),
    );
    final dot = await exporter.generateDotGraph();

    expect(dot, contains('"l1" [label="a\\nOne"]'));
    expect(dot, contains('"l1" -> "l2"'));
  });
}
