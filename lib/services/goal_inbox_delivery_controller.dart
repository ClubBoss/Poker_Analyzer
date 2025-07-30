import '../models/xp_guided_goal.dart';
import 'goal_slot_allocator.dart';
import 'inbox_booster_tracker_service.dart';

/// Queues XP goals for delivery via the theory inbox banner.
class GoalInboxDeliveryController {
  final InboxBoosterTrackerService tracker;

  GoalInboxDeliveryController({InboxBoosterTrackerService? tracker})
      : tracker = tracker ?? InboxBoosterTrackerService.instance;

  static final GoalInboxDeliveryController instance =
      GoalInboxDeliveryController();

  List<GoalSlotAssignment> _assignments = [];

  /// Replaces the current queue with [assignments].
  void updateAssignments(List<GoalSlotAssignment> assignments) {
    _assignments = List.from(assignments);
  }

  /// Returns prioritized inbox goals after filtering. Returned goals are marked
  /// as shown via [InboxBoosterTrackerService].
  Future<List<XPGuidedGoal>> getInboxGoals({int maxGoals = 2}) async {
    if (maxGoals <= 0 || _assignments.isEmpty) return [];

    final seenIds = <String>{};
    final items = <_Candidate>[];
    var index = 0;
    for (final a in _assignments) {
      index++;
      if (a.slot != 'theory' && a.slot != 'home') continue;
      final id = a.goal.id;
      if (!seenIds.add(id)) continue;
      if (await tracker.wasRecentlyShown(id)) continue;
      final score = a.goal.xp.toDouble() + (1000 - index) / 1000.0;
      items.add(_Candidate(a.goal, score));
    }

    if (items.isEmpty) return [];
    items.sort((a, b) => b.score.compareTo(a.score));

    final goals = <XPGuidedGoal>[];
    for (final c in items.take(maxGoals)) {
      goals.add(c.goal);
      await tracker.markShown(c.goal.id);
    }
    return goals;
  }
}

class _Candidate {
  final XPGuidedGoal goal;
  final double score;
  _Candidate(this.goal, this.score);
}
