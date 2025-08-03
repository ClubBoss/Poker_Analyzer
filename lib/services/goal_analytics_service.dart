import '../models/user_goal.dart';
import 'package:poker_analyzer/services/preferences_service.dart';
import 'user_action_logger.dart';

class GoalAnalyticsService {
  GoalAnalyticsService._();
  static final instance = GoalAnalyticsService._();

  static const _completionPrefix = 'goal_completed_logged_';

  Future<void> logGoalCreated(UserGoal goal) async {
    await _logEvent('goal_created', goal, 0);
  }

  Future<void> logGoalProgress(UserGoal goal, double progress) async {
    await _logEvent('goal_progress', goal, progress);
  }

  Future<void> logGoalCompleted(UserGoal goal) async {
    final prefs = await PreferencesService.getInstance();
    final key = '$_completionPrefix${goal.id}';
    if (prefs.getBool(key) == true) return;
    await _logEvent('goal_completed', goal, 100);
    await prefs.setBool(key, true);
  }

  Future<void> _logEvent(
      String type, UserGoal goal, double progress) async {
    final event = {
      'event': type,
      'goalId': goal.id,
      'tag': goal.tag,
      'targetAccuracy': goal.targetAccuracy,
      'progress': progress,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await UserActionLogger.instance.logEvent(event);
  }

  Future<List<Map<String, dynamic>>> getGoalHistory() async {
    await UserActionLogger.instance.load();
    return [
      for (final e in UserActionLogger.instance.events)
        if (e['goalId'] != null) Map<String, dynamic>.from(e)
    ];
  }
}
