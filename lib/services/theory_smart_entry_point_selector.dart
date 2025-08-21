import 'dart:math';

import '../models/theory_mini_lesson_node.dart';
import 'mini_lesson_library_service.dart';
import 'mini_lesson_progress_tracker.dart';
import 'theory_lesson_review_queue.dart';

/// Chooses the best mini lesson to open when entering the theory map.
class TheorySmartEntryPointSelector {
  final MiniLessonLibraryService library;
  final MiniLessonProgressTracker progress;
  final TheoryLessonReviewQueue review;

  TheorySmartEntryPointSelector({
    MiniLessonLibraryService? library,
    MiniLessonProgressTracker? progress,
    TheoryLessonReviewQueue? review,
  }) : library = library ?? MiniLessonLibraryService.instance,
       progress = progress ?? MiniLessonProgressTracker.instance,
       review = review ?? TheoryLessonReviewQueue.instance;

  static final TheorySmartEntryPointSelector instance =
      TheorySmartEntryPointSelector();

  /// Picks the best starting mini lesson using [focusTags], completion state
  /// and recent mistakes. Returns null when no lessons are available.
  Future<TheoryMiniLessonNode?> pickSmartStartLesson({
    Set<String> focusTags = const {},
  }) async {
    await library.loadAll();
    final normalized = {for (final t in focusTags) t.trim().toLowerCase()}
      ..removeWhere((e) => e.isEmpty);

    // 1) unfinished lesson matching focus tags
    if (normalized.isNotEmpty) {
      for (final lesson in library.all) {
        if (await progress.isCompleted(lesson.id)) continue;
        final tags = lesson.tags.map((e) => e.trim().toLowerCase());
        if (tags.any(normalized.contains)) {
          return lesson;
        }
      }
    }

    // 2) recent mistakes matching focus tags
    final reviewLessons = await review.getNextLessonsToReview(
      limit: 1,
      focusTags: normalized,
    );
    if (reviewLessons.isNotEmpty) {
      final l = reviewLessons.first;
      if (!await progress.isCompleted(l.id)) return l;
    }

    // 3) random unfinished lesson
    final remaining = [
      for (final l in library.all)
        if (!await progress.isCompleted(l.id)) l,
    ];
    if (remaining.isEmpty) return null;
    final rand = Random();
    return remaining[rand.nextInt(remaining.length)];
  }
}
