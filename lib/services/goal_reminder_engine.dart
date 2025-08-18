import '../models/training_goal.dart';
import 'goal_suggestion_service.dart';
import 'smart_goal_tracking_service.dart';
import 'session_log_service.dart';
import 'goal_completion_engine.dart';
import 'pack_library_loader_service.dart';

/// Detects inactive training goals and surfaces them to the user.
class GoalReminderEngine {
  final GoalSuggestionService suggestions;
  final SessionLogService logs;
  final SmartGoalTrackingService tracker;

  GoalReminderEngine({
    required this.suggestions,
    required this.logs,
    SmartGoalTrackingService? tracker,
  }) : tracker = tracker ?? SmartGoalTrackingService(logs: logs);

  /// Returns goals that haven't seen progress in over three days and
  /// are not yet completed.
  Future<List<TrainingGoal>> getStaleGoals() async {
    final progress = await logs.getUserProgress();
    final goals = await suggestions.suggestGoals(progress: progress);
    final result = <TrainingGoal>[];
    for (final g in goals) {
      final tag = g.tag;
      if (tag == null) continue;
      final prog = await tracker.getGoalProgress(tag);
      if (GoalCompletionEngine.instance.isGoalCompleted(prog)) continue;
      final last = await _lastActivity(tag);
      if (last == null ||
          DateTime.now().difference(last) > const Duration(days: 3)) {
        result.add(g);
      }
    }
    return result;
  }

  Future<DateTime?> _lastActivity(String tag) async {
    await logs.load();
    await PackLibraryLoaderService.instance.loadLibrary();
    final library = {
      for (final t in PackLibraryLoaderService.instance.library) t.id: t,
    };
    final normalized = tag.trim().toLowerCase();
    DateTime? last;
    for (final log in logs.logs) {
      final tpl = library[log.templateId];
      if (tpl == null) continue;
      if (!tpl.tags.contains(normalized)) continue;
      if (last == null || log.completedAt.isAfter(last)) {
        last = log.completedAt;
      }
    }
    return last;
  }
}
