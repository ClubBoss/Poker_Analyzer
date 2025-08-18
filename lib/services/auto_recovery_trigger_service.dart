import '../main.dart';
import 'notification_service.dart';
import 'tag_insight_reminder_engine.dart';
import 'tag_goal_tracker_service.dart';
import 'pack_library_service.dart';
import 'scheduled_training_queue_service.dart';

/// Automatically queues recovery drills when skill loss is detected.
class AutoRecoveryTriggerService {
  final TagInsightReminderEngine reminder;
  final TagGoalTrackerService goals;
  final PackLibraryService library;
  final ScheduledTrainingQueueService queue;

  AutoRecoveryTriggerService({
    required this.reminder,
    required this.queue,
    TagGoalTrackerService? goals,
    PackLibraryService? library,
  }) : goals = goals ?? TagGoalTrackerService.instance,
       library = library ?? PackLibraryService.instance;

  /// Checks for skill losses and schedules review packs if needed.
  Future<void> run() async {
    final losses = await reminder.loadLosses();
    bool anyQueued = false;
    for (final loss in losses) {
      final progress = await goals.getProgress(loss.tag);
      final last = progress.lastTrainingDate;
      if (last != null &&
          DateTime.now().difference(last) < const Duration(days: 3)) {
        continue;
      }
      final tpl = await library.findByTag(loss.tag);
      if (tpl != null) {
        await queue.add(tpl.id);
        anyQueued = true;
      }
    }
    if (anyQueued) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        await NotificationService.scheduleDailyReminder(ctx);
      }
    }
  }
}
