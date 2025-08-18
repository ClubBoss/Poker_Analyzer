import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/theory_lesson_reachability_validator.dart';
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

  test('validator detects unreachable and orphaned lessons', () {
    final lessons = [
      TheoryMiniLessonNode(id: 'a', title: 'A', content: '', nextIds: ['b']),
      TheoryMiniLessonNode(id: 'b', title: 'B', content: '', nextIds: ['c']),
      TheoryMiniLessonNode(id: 'c', title: 'C', content: '', nextIds: []),
      TheoryMiniLessonNode(id: 'orphan', title: 'O', content: '', nextIds: []),
      TheoryMiniLessonNode(
        id: 'cycle1',
        title: '',
        content: '',
        nextIds: ['cycle2'],
      ),
      TheoryMiniLessonNode(
        id: 'cycle2',
        title: '',
        content: '',
        nextIds: ['cycle1'],
      ),
    ];

    final library = _FakeLibrary(lessons);
    final validator = TheoryLessonReachabilityValidator(library: library);
    final result = validator.validate(rootIds: ['a']);

    expect(result.orphanIds, contains('orphan'));
    expect(result.unreachableIds, contains('orphan'));
    expect(result.cycleIds, contains('cycle1'));
    expect(result.cycleIds, contains('cycle2'));
    expect(result.unreachableIds.contains('b'), isFalse);
  });
}
