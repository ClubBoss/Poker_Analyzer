import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import 'lesson_streak_tracker_service.dart';
import 'theory_lesson_completion_logger.dart';
import 'notification_service.dart';

/// Schedules reminders when the lesson streak is at risk.
class StreakReminderSchedulerService {
  StreakReminderSchedulerService({
    this.logger = TheoryLessonCompletionLogger(),
    this.streak = LessonStreakTrackerService.instance,
  });

  /// Logs lesson completions.
  final TheoryLessonCompletionLogger logger;

  /// Tracks current lesson streak.
  final LessonStreakTrackerService streak;

  static const String _hourKey = 'streak_reminder_hour';
  static const String _muteKey = 'streak_reminder_muted';
  static const String _lastKey = 'streak_reminder_last';

  int _hour = 20;
  bool _muted = false;
  Timer? _timer;

  /// Initializes the scheduler and begins daily checks.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _hour = prefs.getInt(_hourKey) ?? 20;
    _muted = prefs.getBool(_muteKey) ?? false;
    _schedule();
  }

  /// Updates the daily reminder hour.
  Future<void> setHour(int hour) async {
    final prefs = await SharedPreferences.getInstance();
    _hour = hour;
    await prefs.setInt(_hourKey, hour);
    _schedule();
  }

  /// Enables or disables notifications.
  Future<void> setMuted(bool muted) async {
    final prefs = await SharedPreferences.getInstance();
    _muted = muted;
    await prefs.setBool(_muteKey, muted);
    if (muted) {
      _timer?.cancel();
    } else {
      _schedule();
    }
  }

  void dispose() {
    _timer?.cancel();
  }

  void _schedule() {
    _timer?.cancel();
    if (_muted) return;
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, _hour);
    if (next.isBefore(now)) next = next.add(const Duration(days: 1));
    _timer = Timer(next.difference(now), () async {
      await _evaluate();
      _schedule();
    });
  }

  Future<void> _evaluate() async {
    if (_muted) return;
    if (!await shouldNotifyToday()) return;
    final today = DateTime.now();
    final count = await logger.getCompletionsCountFor(today);
    if (count > 0) return;
    final current = await streak.getCurrentStreak();
    if (current < 3) return;
    await NotificationService.schedule(
      id: 331,
      when: DateTime.now().add(const Duration(seconds: 1)),
      body: 'Your streak is in danger! Complete a lesson today.',
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastKey, DateTime.now().toIso8601String());
  }

  /// Returns true if the user hasn't been notified today.
  Future<bool> shouldNotifyToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastStr = prefs.getString(_lastKey);
    if (lastStr == null) return true;
    final last = DateTime.tryParse(lastStr);
    if (last == null) return true;
    final now = DateTime.now();
    return !(last.year == now.year &&
        last.month == now.month &&
        last.day == now.day);
  }
}

