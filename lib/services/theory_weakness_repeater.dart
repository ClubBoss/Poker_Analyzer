import '../models/theory_mini_lesson_node.dart';
import 'mini_lesson_library_service.dart';
import 'mini_lesson_progress_tracker.dart';

/// Suggests previously failed theory lessons for spaced repetition.
class TheoryWeaknessRepeater {
  final MiniLessonLibraryService library;
  final MiniLessonProgressTracker progress;

  const TheoryWeaknessRepeater({
    MiniLessonLibraryService? library,
    MiniLessonProgressTracker? progress,
  })  : library = library ?? MiniLessonLibraryService.instance,
        progress = progress ?? MiniLessonProgressTracker.instance;

  /// Returns lessons ranked by failure recency and EV loss.
  Future<List<TheoryMiniLessonNode>> recommend({
    int limit = 5,
    int minDays = 3,
  }) async {
    await library.loadAll();
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: minDays));
    final scored = <_Entry>[];

    for (final lesson in library.all) {
      final failures = await progress.failures(lesson.id);
      if (failures.isEmpty) continue;
      final last = failures.first.timestamp;
      if (last.isAfter(cutoff)) continue;
      final days = now.difference(last).inDays;
      var loss = 0.0;
      for (final f in failures) {
        loss += f.evLoss.abs();
      }
      final score = days + loss;
      scored.add(_Entry(lesson, score));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return [for (final s in scored.take(limit)) s.lesson];
  }
}

class _Entry {
  final TheoryMiniLessonNode lesson;
  final double score;
  _Entry(this.lesson, this.score);
}
