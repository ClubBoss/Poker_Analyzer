import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../main.dart';
import '../screens/theory_lesson_viewer_screen.dart';
import 'app_settings_service.dart';
import 'app_usage_tracker.dart';
import 'mini_lesson_library_service.dart';
import 'mini_lesson_progress_tracker.dart';
import 'theory_tag_decay_tracker.dart';
import 'decay_topic_suppressor_service.dart';

/// Schedules weekly push notifications for highly decayed theory tags.
class DecayBoosterNotificationService with WidgetsBindingObserver {
  DecayBoosterNotificationService({
    TheoryTagDecayTracker? decay,
    MiniLessonProgressTracker? progress,
    MiniLessonLibraryService? lessons,
    AppUsageTracker? usage,
  })  : decay = decay ?? TheoryTagDecayTracker(),
        progress = progress ?? MiniLessonProgressTracker.instance,
        lessons = lessons ?? MiniLessonLibraryService.instance,
        usage = usage ?? AppUsageTracker.instance;

  final TheoryTagDecayTracker decay;
  final MiniLessonProgressTracker progress;
  final MiniLessonLibraryService lessons;
  final AppUsageTracker usage;

  static final DecayBoosterNotificationService instance =
      DecayBoosterNotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _lastKey = 'decay_booster_push_last';
  static const _ids = [401, 402];

  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
    await _run();
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _run();
    }
  }

  Future<void> _initPlugin() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (r) async {
        final id = r.payload;
        if (id == null) return;
        final ctx = navigatorKey.currentState?.context;
        await lessons.loadAll();
        final lesson = lessons.getById(id);
        if (ctx != null && lesson != null) {
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
        }
      },
    );
    tz.initializeTimeZones();
    _initialized = true;
  }

  Future<void> _run() async {
    await _initPlugin();
    await AppSettingsService.instance.load();
    if (!AppSettingsService.instance.notificationsEnabled) return;

    final idle = await usage.idleDuration();
    if (idle < const Duration(days: 3)) return;

    final prefs = await SharedPreferences.getInstance();
    final lastStr = prefs.getString(_lastKey);
    if (lastStr != null) {
      final last = DateTime.tryParse(lastStr);
      if (last != null && DateTime.now().difference(last).inDays < 7) {
        return;
      }
    }

    final scores = await decay.computeDecayScores();
    final candidates = scores.entries.where((e) => e.value > 50).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (candidates.isEmpty) return;

    await lessons.loadAll();
    final now = DateTime.now();
    const recency = Duration(days: 7);

    int sent = 0;
    int idIndex = 0;
    for (final entry in candidates) {
      final tag = entry.key;
      if (await DecayTopicSuppressorService.instance.shouldSuppress(tag)) {
        continue;
      }
      final list = lessons.findByTags([tag]);
      for (final l in list) {
        final ts = await progress.lastViewed(l.id);
        if (ts != null && now.difference(ts) < recency) continue;
        final when = tz.TZDateTime.now(tz.local).add(const Duration(hours: 1));
        await _plugin.zonedSchedule(
          _ids[idIndex],
          'Time to refresh your skills!',
          'You\u2019re forgetting $tag \u2014 tap to review now',
          when,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'decay_booster',
              'Decay Booster',
            ),
            iOS: DarwinNotificationDetails(),
          ),
          payload: l.id,
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        unawaited(DecayTopicSuppressorService.instance.recordIgnored(tag));
        sent++;
        idIndex = (idIndex + 1) % _ids.length;
        break;
      }
      if (sent >= _ids.length) break;
    }

    if (sent > 0) {
      await prefs.setString(_lastKey, DateTime.now().toIso8601String());
    }
  }
}
