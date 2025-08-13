import 'package:shared_preferences/shared_preferences.dart';

import 'goal_reengagement_service.dart';
import 'daily_training_reminder_service.dart';
import '../models/training_goal.dart';

/// Schedules reminder push notifications for stale goals.
class SmartPushSchedulerService {
  final GoalReengagementService reengagement;
  final DailyTrainingReminderService reminder;

  SmartPushSchedulerService({
    required this.reengagement,
    required this.reminder,
  });

  /// Picks a stale goal and schedules a one-time push if allowed.
  Future<void> maybeScheduleReminderPush() async {
    final TrainingGoal? goal = await reengagement.pickReengagementGoal();
    final tag = goal?.tag?.trim().toLowerCase();
    if (tag == null || tag.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'push_last_shown:$tag';
    final lastStr = prefs.getString(key);
    if (lastStr != null) {
      final last = DateTime.tryParse(lastStr);
      if (last != null &&
          DateTime.now().difference(last) < const Duration(hours: 48)) {
        return;
      }
    }

    final body = "Цель '$tag' ждёт вашего возвращения. Продолжим?";
    await reminder.scheduleOneTimePush(body);
    await prefs.setString(key, DateTime.now().toIso8601String());
  }
}
