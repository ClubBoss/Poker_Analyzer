import 'package:flutter/material.dart';
import 'package:poker_analyzer/services/preferences_service.dart';

import 'learning_path_reminder_engine.dart';
import 'notification_service.dart';
import '../widgets/learning_path_modal_reminder.dart';
import 'training_session_service.dart';
import 'streak_tracker_service.dart';

/// Performs daily app checks and triggers gentle reminders.
class DailyAppCheckService {
  DailyAppCheckService._(this.reminder);

  static DailyAppCheckService? _instance;
  final LearningPathReminderEngine reminder;

  factory DailyAppCheckService({required LearningPathReminderEngine reminder}) {
    return _instance ??= DailyAppCheckService._(reminder);
  }

  static DailyAppCheckService get instance => _instance!;

  static const _lastKey = 'daily_app_check_last';

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> run(BuildContext context) async {
    final prefs = await PreferencesService.getInstance();
    final now = DateTime.now();
    final lastStr = prefs.getString(_lastKey);
    final last = lastStr != null ? DateTime.tryParse(lastStr) : null;
    if (last != null && _sameDay(last, now)) return;
    await prefs.setString(_lastKey, now.toIso8601String());

    await StreakTrackerService.instance.checkAndHandleStreakBreak(context);

    final remind = await reminder.shouldRemindUser();
    if (remind) {
      final active =
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
      final sessions = context.read<TrainingSessionService>();
      final trainingActive =
          sessions.currentSession != null && !sessions.isCompleted;
      if (context.mounted && active && !trainingActive) {
        await LearningPathModalReminder.show(context);
      } else {
        await NotificationService.scheduleDailyReminder(context);
      }
    }
  }
}
