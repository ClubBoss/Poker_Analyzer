import 'mini_lesson_library_service.dart';
import 'mini_lesson_progress_tracker.dart';
import 'session_log_service.dart';
import 'training_session_service.dart';
import '../models/theory_mini_lesson_node.dart';

/// Provides a personalized queue of theory mini lessons to review.
class TheoryLessonReviewQueue {
  final MiniLessonLibraryService library;
  final MiniLessonProgressTracker progress;
  final SessionLogService logs;

  TheoryLessonReviewQueue({
    MiniLessonLibraryService? library,
    MiniLessonProgressTracker? progress,
    SessionLogService? logs,
  }) : library = library ?? MiniLessonLibraryService.instance,
       progress = progress ?? MiniLessonProgressTracker.instance,
       logs = logs ?? SessionLogService(sessions: TrainingSessionService());

  static final TheoryLessonReviewQueue instance = TheoryLessonReviewQueue();

  /// Returns the next [limit] lessons to review, optionally filtered by [focusTags].
  Future<List<TheoryMiniLessonNode>> getNextLessonsToReview({
    int limit = 5,
    Set<String> focusTags = const {},
  }) async {
    if (limit <= 0) return [];
    await library.loadAll();
    await logs.load();

    final mistakeMap = logs.getRecentMistakes();
    final normalizedFocus = {for (final t in focusTags) t.trim().toLowerCase()}
      ..removeWhere((e) => e.isEmpty);

    final entries = <_Entry>[];
    for (final lesson in library.all) {
      if (normalizedFocus.isNotEmpty &&
          !lesson.tags
              .map((e) => e.trim().toLowerCase())
              .any(normalizedFocus.contains)) {
        continue;
      }
      final completed = await progress.isCompleted(lesson.id);
      final last = await progress.lastViewed(lesson.id);
      var mistakes = 0;
      for (final tag in lesson.tags) {
        final key = tag.trim().toLowerCase();
        mistakes += mistakeMap[key] ?? 0;
      }
      entries.add(_Entry(lesson, completed, mistakes, last));
    }

    entries.sort((a, b) {
      if (a.completed != b.completed) {
        return a.completed ? 1 : -1;
      }
      if (a.mistakes != b.mistakes) {
        return b.mistakes.compareTo(a.mistakes);
      }
      final at = a.lastViewed ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.lastViewed ?? DateTime.fromMillisecondsSinceEpoch(0);
      return at.compareTo(bt);
    });

    return [for (final e in entries.take(limit)) e.lesson];
  }
}

class _Entry {
  final TheoryMiniLessonNode lesson;
  final bool completed;
  final int mistakes;
  final DateTime? lastViewed;
  _Entry(this.lesson, this.completed, this.mistakes, this.lastViewed);
}
