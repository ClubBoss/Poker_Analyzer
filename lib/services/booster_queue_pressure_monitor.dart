import 'recap_booster_queue.dart';
import 'goal_queue.dart';
import 'inbox_booster_tracker_service.dart';
import 'smart_skill_gap_booster_engine.dart';

/// Analyzes current booster queues to detect overload situations.
class BoosterQueuePressureMonitor {
  final RecapBoosterQueue recapQueue;
  final GoalQueue goalQueue;
  final InboxBoosterTrackerService inboxQueue;
  final SmartSkillGapBoosterEngine skillGap;

  /// Maximum queue sizes used for pressure normalization.
  final int maxRecap;
  final int maxGoal;
  final int maxInbox;
  final int maxSkillGap;

  BoosterQueuePressureMonitor({
    RecapBoosterQueue? recapQueue,
    GoalQueue? goalQueue,
    InboxBoosterTrackerService? inboxQueue,
    SmartSkillGapBoosterEngine? skillGap,
    this.maxRecap = 3,
    this.maxGoal = 5,
    this.maxInbox = 5,
    this.maxSkillGap = 3,
  })  : recapQueue = recapQueue ?? RecapBoosterQueue.instance,
        goalQueue = goalQueue ?? GoalQueue.instance,
        inboxQueue = inboxQueue ?? InboxBoosterTrackerService.instance,
        skillGap = skillGap ?? const SmartSkillGapBoosterEngine();

  static final BoosterQueuePressureMonitor instance =
      BoosterQueuePressureMonitor();

  /// Computes a normalized pressure score in the range [0.0, 1.0].
  Future<double> computeScore() async {
    final recapLen = recapQueue.getQueue().length;
    final goalLen = goalQueue.getQueue().length;
    final inboxLen = (await inboxQueue.getInbox()).length;
    final gapLen = (await skillGap.recommend(max: maxSkillGap)).length;

    final recapScore = recapLen / maxRecap;
    final goalScore = goalLen / maxGoal;
    final inboxScore = inboxLen / maxInbox;
    final gapScore = gapLen / maxSkillGap;

    final score = (recapScore + goalScore + inboxScore + gapScore) / 4.0;
    if (score < 0) return 0.0;
    if (score > 1) return 1.0;
    return score;
  }

  /// Returns `true` if the combined queue pressure exceeds [threshold].
  Future<bool> isOverloaded({double threshold = 0.85}) async {
    final score = await computeScore();
    return score >= threshold;
  }
}
