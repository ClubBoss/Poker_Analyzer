import '../models/theory_lesson_node.dart';
import '../models/theory_mini_lesson_node.dart';
import 'decay_tag_retention_tracker_service.dart';
import 'mini_lesson_library_service.dart';
import 'theory_lesson_effectiveness_analyzer_service.dart';

/// Selects highly effective theory lessons for decayed tags.
///
/// This service leverages [TheoryLessonEffectivenessAnalyzerService] to find
/// lessons with strong historical impact on recall. For the most decayed tags
/// reported by [DecayTagRetentionTrackerService] it suggests the top lessons so
/// they can be injected as boosters.
class EffectiveTheoryInjectorService {
  final TheoryLessonEffectivenessAnalyzerService analyzer;
  final DecayTagRetentionTrackerService retention;
  final MiniLessonLibraryService library;

  EffectiveTheoryInjectorService({
    TheoryLessonEffectivenessAnalyzerService? analyzer,
    DecayTagRetentionTrackerService? retention,
    MiniLessonLibraryService? library,
  }) : analyzer = analyzer ?? TheoryLessonEffectivenessAnalyzerService(),
       retention = retention ?? DecayTagRetentionTrackerService(),
       library = library ?? MiniLessonLibraryService.instance;

  /// Returns up to two [TheoryLessonNode]s for [tag] that have high historical
  /// effectiveness. The lessons are ordered by their average gain in descending
  /// order. Returns an empty list when no suitable lessons are found.
  Future<List<TheoryLessonNode>> getInjectableLessonsForTag(String tag) async {
    final norm = tag.trim().toLowerCase();
    if (norm.isEmpty) return const [];
    await library.loadAll();
    final lessons = library.all.where((l) {
      return l.tags.any((t) => t.toLowerCase() == norm);
    }).toList();
    if (lessons.isEmpty) return const [];

    final gains = await analyzer.getTopEffectiveLessons(minSessions: 1);
    final candidates = <_Entry>[];
    for (final l in lessons) {
      final gain = gains[l.id];
      if (gain != null && gain > 0) {
        candidates.add(_Entry(l, gain));
      }
    }
    if (candidates.isEmpty) return const [];
    candidates.sort((a, b) => b.gain.compareTo(a.gain));
    return [
      for (final e in candidates.take(2))
        TheoryLessonNode(
          id: e.lesson.id,
          refId: e.lesson.refId,
          title: e.lesson.title,
          content: e.lesson.content,
          nextIds: const [],
          recoveredFromMistake: e.lesson.recoveredFromMistake,
        ),
    ];
  }

  /// Returns a map of decayed tags to their top theory lessons.
  ///
  /// Only tags that have at least one effective lesson are included. The
  /// [limit] parameter controls the maximum number of tags to return.
  Future<Map<String, List<TheoryLessonNode>>> getTopTheoryBoosters({
    int limit = 3,
  }) async {
    if (limit <= 0) return <String, List<TheoryLessonNode>>{};
    final decayed = await retention.getMostDecayedTags(limit * 2);
    final result = <String, List<TheoryLessonNode>>{};
    for (final entry in decayed) {
      if (result.length >= limit) break;
      final lessons = await getInjectableLessonsForTag(entry.key);
      if (lessons.isNotEmpty) {
        result[entry.key] = lessons;
      }
    }
    return result;
  }
}

class _Entry {
  final TheoryMiniLessonNode lesson;
  final double gain;
  _Entry(this.lesson, this.gain);
}
