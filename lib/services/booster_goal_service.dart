import '../models/xp_guided_goal.dart';
import 'goal_queue.dart';
import 'inbox_booster_tracker_service.dart';

/// Turns queued boosters into XP goals for the goal engine.
class BoosterGoalService {
  final GoalQueue queue;
  final InboxBoosterTrackerService tracker;

  BoosterGoalService({GoalQueue? queue, InboxBoosterTrackerService? tracker})
    : queue = queue ?? GoalQueue.instance,
      tracker = tracker ?? InboxBoosterTrackerService.instance;

  static final BoosterGoalService instance = BoosterGoalService();

  /// Returns XP goals built from the queued mini lessons.
  /// [maxGoals] limits how many goals are returned.
  List<XPGuidedGoal> getGoals({int maxGoals = 2}) {
    final lessons = queue.getQueue();
    if (lessons.isEmpty) return [];

    final goals = <XPGuidedGoal>[];
    for (final l in lessons.take(maxGoals)) {
      goals.add(
        XPGuidedGoal(
          id: l.id,
          label: 'Пройти мини-урок: ${l.resolvedTitle}',
          xp: 25,
          source: 'booster',
          onComplete: () {
            tracker.markClicked(l.id);
            queue.remove(l.id);
          },
        ),
      );
    }
    return goals;
  }
}
