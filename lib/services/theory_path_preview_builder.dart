import '../models/theory_mini_lesson_node.dart';
import 'mini_lesson_library_service.dart';

/// Builds a simplified forward chain of theory mini lessons starting from a root id.
class TheoryPathPreviewBuilder {
  final MiniLessonLibraryService library;

  TheoryPathPreviewBuilder({MiniLessonLibraryService? library})
    : library = library ?? MiniLessonLibraryService.instance;

  /// Returns up to [maxDepth] lessons starting from [rootId].
  /// Traversal follows the first `nextId` of each lesson and stops if a cycle
  /// is detected or `maxDepth` is reached.
  Future<List<TheoryMiniLessonNode>> build(
    String rootId, {
    int maxDepth = 10,
  }) async {
    if (rootId.isEmpty || maxDepth <= 0) return const [];
    await library.loadAll();
    final result = <TheoryMiniLessonNode>[];
    final visited = <String>{};
    var currentId = rootId;
    while (result.length < maxDepth && visited.add(currentId)) {
      final node = library.getById(currentId);
      if (node == null) break;
      result.add(node);
      if (node.nextIds.isEmpty) break;
      currentId = node.nextIds.first;
    }
    return result;
  }
}
