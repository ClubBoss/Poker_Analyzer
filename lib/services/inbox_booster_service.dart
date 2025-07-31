import '../models/theory_mini_lesson_node.dart';
import 'inbox_booster_tracker_service.dart';

/// Simple helper that queues boosters for inbox delivery.
class InboxBoosterService {
  final InboxBoosterTrackerService tracker;

  InboxBoosterService({InboxBoosterTrackerService? tracker})
      : tracker = tracker ?? InboxBoosterTrackerService.instance;

  static final InboxBoosterService instance = InboxBoosterService();

  /// Adds [lesson] to the inbox queue if not already present.
  Future<void> inject(TheoryMiniLessonNode lesson) async {
    await tracker.addToInbox(lesson.id);
  }
}
