import '../models/theory_mini_lesson_node.dart';
import '../models/v2/training_spot_v2.dart';
import 'theory_recall_evaluator.dart';
import 'booster_slot_allocator.dart';
import 'recap_booster_queue.dart';
import 'inbox_booster_tracker_service.dart';
import 'goal_queue.dart';
import 'booster_queue_pressure_monitor.dart';
import 'theory_injection_horizon_service.dart';

/// Injects theory boosters into recap, inbox, or goal queues after training spots.
class SmartBoosterInjector {
  final TheoryRecallEvaluator recall;
  final BoosterSlotAllocator allocator;
  final RecapBoosterQueue recapQueue;
  final InboxBoosterTrackerService inboxTracker;
  final GoalQueue goalQueue;

  SmartBoosterInjector({
    TheoryRecallEvaluator? recall,
    BoosterSlotAllocator? allocator,
    RecapBoosterQueue? recapQueue,
    InboxBoosterTrackerService? inboxTracker,
    GoalQueue? goalQueue,
  })  : recall = recall ?? const TheoryRecallEvaluator(),
        allocator = allocator ?? BoosterSlotAllocator.instance,
        recapQueue = recapQueue ?? RecapBoosterQueue.instance,
        inboxTracker = inboxTracker ?? InboxBoosterTrackerService.instance,
        goalQueue = goalQueue ?? GoalQueue.instance;

  static final SmartBoosterInjector instance = SmartBoosterInjector();

  /// Evaluates [candidateBoosters] for [completedSpot] and enqueues the best one.
  Future<void> injectBooster(
    TrainingSpotV2 completedSpot,
    List<TheoryMiniLessonNode> candidateBoosters,
  ) async {
    if (await BoosterQueuePressureMonitor.instance.isOverloaded()) return;
    if (candidateBoosters.isEmpty) return;
    final ranked = await recall.rank(candidateBoosters, completedSpot);
    for (final lesson in ranked) {
      final slot = await allocator.decideSlot(lesson, completedSpot);
      if (slot == BoosterSlot.recap) {
        if (await TheoryInjectionHorizonService.instance.canInject('recap')) {
          await recapQueue.add(lesson.id);
          await TheoryInjectionHorizonService.instance.markInjected('recap');
          break;
        }
      } else if (slot == BoosterSlot.inbox) {
        if (await TheoryInjectionHorizonService.instance.canInject('inbox')) {
          await inboxTracker.addToInbox(lesson.id);
          await TheoryInjectionHorizonService.instance.markInjected('inbox');
          break;
        }
      } else if (slot == BoosterSlot.goal) {
        if (await TheoryInjectionHorizonService.instance.canInject('goal')) {
          goalQueue.push(lesson);
          await TheoryInjectionHorizonService.instance.markInjected('goal');
          break;
        }
      }
    }
  }
}
