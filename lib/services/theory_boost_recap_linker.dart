import '../models/theory_mini_lesson_node.dart';
import 'mini_lesson_library_service.dart';

/// Links booster tags to theory mini lessons for recap suggestions.
class TheoryBoostRecapLinker {
  /// Mapping of booster tag to lesson id.
  final Map<String, String> tagMap;

  /// Creates a linker with an optional [tagMap]. Defaults to [_defaultMap].
  TheoryBoostRecapLinker({Map<String, String>? tagMap})
    : tagMap = tagMap ?? _defaultMap;

  static const Map<String, String> _defaultMap = {
    'bubble_fold': 'bubble_fold',
    'iso_vs_limp': 'iso_vs_limp',
  };

  /// Returns the lesson id linked to [tag] or null if none found.
  /// Matching is case-insensitive and also supports prefix matches.
  String? getLinkedLesson(String tag) {
    final key = tag.trim();
    if (key.isEmpty) return null;
    final direct = tagMap[key];
    if (direct != null) return direct;
    final lower = key.toLowerCase();
    final lowerMatch = tagMap[lower];
    if (lowerMatch != null) return lowerMatch;
    for (final entry in tagMap.entries) {
      if (lower.startsWith(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    return null;
  }

  /// Convenience to get the actual lesson node for [tag].
  Future<TheoryMiniLessonNode?> fetchLesson(String tag) async {
    await MiniLessonLibraryService.instance.loadAll();
    final id = getLinkedLesson(tag);
    return id != null ? MiniLessonLibraryService.instance.getById(id) : null;
  }
}
