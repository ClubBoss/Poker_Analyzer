import '../models/memory_reminder.dart';
import 'booster_queue_service.dart';
import 'decay_booster_reminder_engine.dart';
import 'review_streak_evaluator_service.dart';
import 'pack_recall_stats_service.dart';

/// Coordinates multiple memory reminder signals and ranks them by priority.
class DecayBoosterReminderOrchestrator {
  final BoosterQueueService queue;
  final DecayBoosterReminderEngine boosterEngine;
  final ReviewStreakEvaluatorService streak;
  final PackRecallStatsService recall;

  DecayBoosterReminderOrchestrator({
    BoosterQueueService? queue,
    DecayBoosterReminderEngine? boosterEngine,
    ReviewStreakEvaluatorService? streak,
    PackRecallStatsService? recall,
  }) : queue = queue ?? BoosterQueueService.instance,
       boosterEngine = boosterEngine ?? DecayBoosterReminderEngine(),
       streak = streak ?? const ReviewStreakEvaluatorService(),
       recall = recall ?? PackRecallStatsService.instance;

  /// Whether a decay booster banner should be shown.
  Future<bool> shouldShowDecayBoosterBanner() async {
    if (queue.getQueue().isNotEmpty) return true;
    return boosterEngine.shouldShowReminder();
  }

  /// Whether to show a broken streak banner.
  Future<List<String>> brokenStreakPacks() async {
    return streak.packsWithBrokenStreaks();
  }

  /// Whether to show upcoming review banner.
  Future<List<String>> upcomingReviewPacks() async {
    return recall.upcomingReviewPacks();
  }

  /// Returns ranked memory reminders.
  Future<List<MemoryReminder>> getRankedReminders() async {
    final list = <MemoryReminder>[];

    if (await shouldShowDecayBoosterBanner()) {
      list.add(
        MemoryReminder(type: MemoryReminderType.decayBooster, priority: 3),
      );
    }

    final broken = await brokenStreakPacks();
    if (broken.isNotEmpty) {
      list.add(
        MemoryReminder(
          type: MemoryReminderType.brokenStreak,
          priority: 2,
          packId: broken.first,
        ),
      );
    }

    final upcoming = await upcomingReviewPacks();
    if (upcoming.isNotEmpty) {
      list.add(
        MemoryReminder(
          type: MemoryReminderType.upcomingReview,
          priority: 1,
          packId: upcoming.first,
        ),
      );
    }

    list.sort((a, b) => b.priority.compareTo(a.priority));
    return list;
  }
}
