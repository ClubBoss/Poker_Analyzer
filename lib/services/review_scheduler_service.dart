import 'package:shared_preferences/shared_preferences.dart';

import 'theory_lesson_completion_logger.dart';

/// Determines whether a lesson is due for review based on a
/// simple spaced-repetition schedule.
class ReviewSchedulerService {
  ReviewSchedulerService._();
  static final ReviewSchedulerService instance = ReviewSchedulerService._();

  static const _reviewCountPrefix = 'lesson_review_count_';
  static const List<int> _scheduleDays = [1, 3, 7, 14];

  /// Returns true if [lessonId] was completed and is due for review.
  Future<bool> isDueForReview(String lessonId) async {
    final completedLessons =
        await TheoryLessonCompletionLogger.instance.getCompletedLessons();
    final completedAt = completedLessons[lessonId];
    if (completedAt == null) return false;

    final prefs = await SharedPreferences.getInstance();
    final reviewCount = prefs.getInt('$_reviewCountPrefix$lessonId') ?? 0;
    final scheduleIndex =
        reviewCount < _scheduleDays.length ? reviewCount : _scheduleDays.length - 1;
    final dueDate =
        completedAt.add(Duration(days: _scheduleDays[scheduleIndex]));
    return DateTime.now().isAfter(dueDate);
  }

  /// Increments review count for [lessonId] and updates completion timestamp.
  Future<void> markReviewed(String lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt('$_reviewCountPrefix$lessonId') ?? 0;
    await prefs.setInt('$_reviewCountPrefix$lessonId', count + 1);
    await TheoryLessonCompletionLogger.instance.markCompleted(lessonId);
  }
}

