import '../models/theory_mini_lesson_node.dart';
import 'recap_booster_queue.dart';
import 'inbox_booster_tracker_service.dart';
import 'goal_queue.dart';
import 'theory_booster_recall_engine.dart';
import 'smart_skill_gap_booster_engine.dart';
import 'mini_lesson_progress_tracker.dart';
import 'learning_graph_engine.dart';
import 'learning_path_stage_library.dart';
import 'theory_stage_progress_tracker.dart';
import '../models/stage_type.dart';
import 'path_map_engine.dart';

/// Blocks low priority theory boosters when higher priority content is pending.
class TheoryPriorityGatekeeperService {
  final RecapBoosterQueue recapQueue;
  final InboxBoosterTrackerService inboxQueue;
  final GoalQueue goalQueue;
  final TheoryBoosterRecallEngine recall;
  final SmartSkillGapBoosterEngine skillGap;
  final LearningPathEngine path;

  TheoryPriorityGatekeeperService({
    RecapBoosterQueue? recapQueue,
    InboxBoosterTrackerService? inboxQueue,
    GoalQueue? goalQueue,
    TheoryBoosterRecallEngine? recall,
    SmartSkillGapBoosterEngine? skillGap,
    LearningPathEngine? path,
  })  : recapQueue = recapQueue ?? RecapBoosterQueue.instance,
        inboxQueue = inboxQueue ?? InboxBoosterTrackerService.instance,
        goalQueue = goalQueue ?? GoalQueue.instance,
        recall = recall ?? TheoryBoosterRecallEngine.instance,
        skillGap = skillGap ?? const SmartSkillGapBoosterEngine(),
        path = path ?? LearningPathEngine.instance;

  static final TheoryPriorityGatekeeperService instance =
      TheoryPriorityGatekeeperService();

  final List<String> _reasons = <String>[];

  /// Reasons why the last call to [isBlocked] returned true.
  List<String> getBlockingReasons() => List.unmodifiable(_reasons);

  /// Returns `true` if [lessonId] should not be injected because higher
  /// priority content is pending. Set [force] to bypass the check.
  Future<bool> isBlocked(String lessonId, {bool force = false}) async {
    _reasons.clear();
    if (force) return false;

    // Matching lesson already queued.
    final queued = <String>{
      ...recapQueue.getQueue(),
      ...(await inboxQueue.getInbox()),
      for (final l in goalQueue.getQueue()) l.id,
    };
    if (queued.contains(lessonId)) {
      _reasons.add('alreadyQueued');
      return true;
    }

    // Recall boosters waiting to be completed.
    final recallLessons = await recall.recallUnlaunched();
    if (recallLessons.isNotEmpty) {
      _reasons.add('recallPending');
    }

    // Pending weak skill boosters.
    final weak = await skillGap.recommend(max: 1);
    if (weak.isNotEmpty) {
      final id = weak.first.id;
      if (!await MiniLessonProgressTracker.instance.isCompleted(id)) {
        if (id != lessonId) {
          _reasons.add('weakSkillPending');
        }
      }
    }

    // Uncompleted theory in the current path stage.
    if (await _hasUnlockedTheory()) {
      _reasons.add('stageTheoryPending');
    }

    return _reasons.isNotEmpty;
  }

  Future<bool> _hasUnlockedTheory() async {
    final node = path.getCurrentNode();
    if (node == null) return false;
    if (node is TheoryLessonNode || node is TheoryMiniLessonNode) return true;
    if (node is TheoryStageNode) return true;
    if (node is TrainingStageNode) {
      final stage = LearningPathStageLibrary.instance.getById(node.id);
      if (stage == null) return false;
      if (stage.type == StageType.theory) return true;
      if (stage.theoryPackId != null) {
        final completed =
            await TheoryStageProgressTracker.instance.isCompleted(stage.id);
        return !completed;
      }
    }
    return false;
  }
}
