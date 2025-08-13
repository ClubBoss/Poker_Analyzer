import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/theory_tag_summary_service.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
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

  test('computeSummary aggregates stats per tag', () async {
    final lesson1 = TheoryMiniLessonNode(
      id: 'l1',
      title: 'A1',
      content: '- do this\n- do that',
      tags: const ['a'],
      nextIds: const ['x'],
    );
    final lesson2 = TheoryMiniLessonNode(
      id: 'l2',
      title: 'B1',
      content: 'Example: stuff\n- bullet',
      tags: const ['b', 'a'],
      nextIds: const [],
    );
    final lesson3 = TheoryMiniLessonNode(
      id: 'l3',
      title: 'C1',
      content: 'Just text',
      tags: const ['c'],
      nextIds: const ['y'],
    );
    final library = _FakeLibrary([lesson1, lesson2, lesson3]);
    final service = TheoryTagSummaryService(library: library);

    final summary = await service.computeSummary();

    expect(summary['a']!.lessonCount, 2);
    expect(summary['a']!.exampleCount, 1);
    expect(summary['a']!.connectedToPath, isTrue);
    expect(summary['b']!.lessonCount, 1);
    expect(summary['b']!.exampleCount, 1);
    expect(summary['b']!.connectedToPath, isFalse);
    expect(summary['c']!.connectedToPath, isTrue);
  });
}
