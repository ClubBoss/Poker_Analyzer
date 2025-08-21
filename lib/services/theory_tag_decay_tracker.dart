import 'mini_lesson_library_service.dart';
import 'mini_lesson_progress_tracker.dart';
import 'theory_tag_summary_service.dart';

/// Computes knowledge decay scores for theory tags.
class TheoryTagDecayTracker {
  final MiniLessonLibraryService library;
  final MiniLessonProgressTracker progress;
  final TheoryTagSummaryService summary;

  TheoryTagDecayTracker({
    MiniLessonLibraryService? library,
    MiniLessonProgressTracker? progress,
    TheoryTagSummaryService? summary,
  }) : library = library ?? MiniLessonLibraryService.instance,
       progress = progress ?? MiniLessonProgressTracker.instance,
       summary =
           summary ??
           TheoryTagSummaryService(
             library: library ?? MiniLessonLibraryService.instance,
           );

  /// Returns decay scores for all tags using [now] as reference time.
  Future<Map<String, double>> computeDecayScores({DateTime? now}) async {
    await library.loadAll();
    final stats = await summary.computeSummary();
    final current = now ?? DateTime.now();

    final lastTimes = <String, DateTime?>{};
    for (final lesson in library.all) {
      final ts = await progress.lastViewed(lesson.id);
      for (final tag in lesson.tags) {
        final key = tag.trim().toLowerCase();
        if (key.isEmpty) continue;
        final prev = lastTimes[key];
        if (prev == null || (ts != null && ts.isAfter(prev))) {
          lastTimes[key] = ts;
        }
      }
    }

    final scores = <String, double>{};
    for (final entry in stats.entries) {
      final tag = entry.key;
      final coverage = entry.value.lessonCount;
      final ts = lastTimes[tag];
      final days = ts == null
          ? 9999.0
          : current.difference(ts).inDays.toDouble();
      final decay = days / (coverage > 0 ? coverage : 1);
      scores[tag] = decay;
    }
    return scores;
  }
}
