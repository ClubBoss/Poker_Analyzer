import '../models/theory_mini_lesson_node.dart';
import 'mini_lesson_library_service.dart';

/// Caches theory lessons by tag to avoid repeated library loads.
class InlineTheoryLinkerCache {
  InlineTheoryLinkerCache({MiniLessonLibraryService? library})
      : _library = library ?? MiniLessonLibraryService.instance;

  final MiniLessonLibraryService _library;
  bool _ready = false;
  Future<void>? _loading;

  /// Global singleton instance.
  static final InlineTheoryLinkerCache instance = InlineTheoryLinkerCache();

  /// Ensures the underlying library is loaded. Subsequent calls are no-ops.
  Future<void> ensureReady() {
    if (_ready) return Future.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    await _library.loadAll();
    _ready = true;
  }

  /// Returns all lessons matching any of [tags]. Returns an empty list if the
  /// cache is not ready or no matches are found.
  List<TheoryMiniLessonNode> getMatchesForTags(List<String> tags) {
    if (!_ready) return const [];
    final normalized = tags.map((e) => e.toLowerCase()).toList();
    return _library.findByTags(normalized);
  }

  /// Returns the first lesson matching [tags] or `null` if none found.
  TheoryMiniLessonNode? getFirstMatchForTags(List<String> tags) {
    final matches = getMatchesForTags(tags);
    return matches.isEmpty ? null : matches.first;
  }
}

