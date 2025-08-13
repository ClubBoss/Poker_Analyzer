import '../models/theory_mini_lesson_node.dart';
import 'mini_lesson_library_service.dart';

/// Suggests next lesson links between [TheoryMiniLessonNode]s based on
/// overlapping tags and length heuristics.
class TheoryLessonAutoLinker {
  final MiniLessonLibraryService library;

  /// Creates a new auto linker using [MiniLessonLibraryService.instance] by
  /// default.
  const TheoryLessonAutoLinker({MiniLessonLibraryService? library})
      : library = library ?? MiniLessonLibraryService.instance;

  /// Automatically links all loaded lessons in [library].
  ///
  /// When [dryRun] is true, the suggestions are returned without creating
  /// new lesson objects.
  Future<Map<String, List<String>>> autoLinkAll({
    bool dryRun = false,
    int maxNext = 3,
  }) async {
    await library.loadAll();
    final lessons = library.all;
    final suggestions = suggestLinks(lessons, maxNext: maxNext);
    if (dryRun) return suggestions;
    return suggestions;
  }

  /// Returns a map of lesson id to suggested next lesson ids.
  Map<String, List<String>> suggestLinks(List<TheoryMiniLessonNode> lessons,
      {int maxNext = 3}) {
    final result = <String, List<String>>{};
    for (final lesson in lessons) {
      if (lesson.nextIds.isNotEmpty) continue;
      final len = _wordCount(lesson.content);
      final scored = <_Scored>[];
      for (final other in lessons) {
        if (other.id == lesson.id) continue;
        final overlap = _tagOverlap(lesson, other);
        if (overlap == 0) continue;
        final diff = _wordCount(other.content) - len;
        if (diff <= 0) continue;
        final score = overlap * 10 + diff;
        scored.add(_Scored(other, score));
      }
      if (scored.isEmpty) continue;
      scored.sort((a, b) => b.score.compareTo(a.score));
      result[lesson.id] = [for (final s in scored.take(maxNext)) s.lesson.id];
    }
    return result;
  }

  int _wordCount(String text) => RegExp(r'\w+').allMatches(text).length;

  int _tagOverlap(TheoryMiniLessonNode a, TheoryMiniLessonNode b) {
    final setB = {for (final t in b.tags) t.trim().toLowerCase()};
    return a.tags.where((t) => setB.contains(t.trim().toLowerCase())).length;
  }
}

class _Scored {
  final TheoryMiniLessonNode lesson;
  final int score;
  _Scored(this.lesson, this.score);
}
