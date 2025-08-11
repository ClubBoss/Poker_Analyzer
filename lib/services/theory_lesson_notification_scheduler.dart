import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../main.dart';
import '../screens/theory_lesson_viewer_screen.dart';
import 'app_settings_service.dart';
import 'mini_lesson_library_service.dart';
import 'mini_lesson_progress_tracker.dart';
import 'theory_lesson_resume_engine.dart';

/// Schedules reminder pushes to resume the last incomplete theory lesson.
class TheoryLessonNotificationScheduler {
  TheoryLessonNotificationScheduler._() {
    MiniLessonProgressTracker.instance.onLessonCompleted
        .listen((_) => scheduleReminderIfNeeded());
  }

  /// Singleton instance.
  static final TheoryLessonNotificationScheduler instance =
      TheoryLessonNotificationScheduler._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _id = 334;

  Future<void> _init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (r) async {
        final lessonId = r.payload;
        if (lessonId == null) return;
        final ctx = navigatorKey.currentState?.context;
        if (ctx == null) return;
        await MiniLessonLibraryService.instance.loadAll();
        final lesson = MiniLessonLibraryService.instance.getById(lessonId);
        if (lesson == null) return;
        Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (_) => TheoryLessonViewerScreen(
              lesson: lesson,
              currentIndex: 1,
              totalCount: 1,
            ),
          ),
        );
      },
    );
    tz.initializeTimeZones();
    _initialized = true;
  }

  /// Cancels any scheduled reminder.
  Future<void> cancelReminder() async {
    await _init();
    await _plugin.cancel(_id);
  }

  /// Schedules a reminder notification if there is an incomplete lesson.
  Future<void> scheduleReminderIfNeeded() async {
    await _init();
    await AppSettingsService.instance.load();
    if (!AppSettingsService.instance.notificationsEnabled) return;

    final lesson = await TheoryLessonResumeEngine.instance.getResumeTarget();
    if (lesson == null) {
      await cancelReminder();
      return;
    }

    await _plugin.cancel(_id);
    final when = tz.TZDateTime.now(tz.local).add(const Duration(hours: 6));
    await _plugin.zonedSchedule(
      _id,
      'Продолжите обучение',
      'Вы остановились на: ${lesson.resolvedTitle}',
      when,
      const NotificationDetails(
        android: AndroidNotificationDetails('theory_resume', 'Theory Resume'),
        iOS: DarwinNotificationDetails(),
      ),
      payload: lesson.id,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
