import 'review_scheduler_service.dart';

/// Logs completed reviews and updates the review schedule.
class ReviewCompletionLogger {
  ReviewCompletionLogger._();
  static final ReviewCompletionLogger instance = ReviewCompletionLogger._();

  /// Increments the review count for [lessonId].
  Future<void> logReview(String lessonId) async {
    await ReviewSchedulerService.instance.markReviewed(lessonId);
  }
}
