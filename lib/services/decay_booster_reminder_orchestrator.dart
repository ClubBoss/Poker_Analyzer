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
  })  : queue = queue ?? BoosterQueueService.instance,
        boosterEngine = boosterEngine ?? DecayBoosterReminderEngine(),
        streak = streak ?? const ReviewStreakEvaluatorService(),
        recall = recall ?? PackRecallStatsService.instance;

  /// Whether a decay booster banner should be shown.
  Future<bool> shouldShowDecayBoosterBanner() async {
    if (queue.getQueue().isNotEmpty) return true;
    return boosterEngine.shouldShowReminder();
  }

  /// Whether to show a broken streak banner.
  Future<bool> shouldShowBrokenStreakBanner() async {
    final ids = await streak.packsWithBrokenStreaks();
    return ids.isNotEmpty;
  }

  /// Whether to show upcoming review banner.
  Future<bool> shouldShowUpcomingReviewBanner() async {
    final ids = await recall.upcomingReviewPacks();
    return ids.isNotEmpty;
  }

  /// Returns ranked memory reminders.
  Future<List<MemoryReminder>> getRankedReminders() async {
    final list = <MemoryReminder>[];

    if (await shouldShowDecayBoosterBanner()) {
      list.add(const MemoryReminder(
          type: MemoryReminderType.decayBooster, priority: 3));
    }

    if (await shouldShowBrokenStreakBanner()) {
      list.add(const MemoryReminder(
          type: MemoryReminderType.brokenStreak, priority: 2));
    }

    if (await shouldShowUpcomingReviewBanner()) {
      list.add(const MemoryReminder(
          type: MemoryReminderType.upcomingReview, priority: 1));
    }

    list.sort((a, b) => b.priority.compareTo(a.priority));
    return list;
  }
}
