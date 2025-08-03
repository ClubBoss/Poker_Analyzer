import 'dart:async';
import 'package:poker_analyzer/services/preferences_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/pinned_learning_item.dart';
import 'smart_pinned_recommender_service.dart';
import 'decay_tag_retention_tracker_service.dart';
import 'mini_lesson_library_service.dart';
import 'pack_library_service.dart';
import 'in_app_nudge_service.dart';
import 'nudge_fatigue_detector_service.dart';

/// Periodically nudges the user to resume decayed pinned content when the app
/// is resumed after being idle.
class PinnedComebackNudgeService with WidgetsBindingObserver {
  PinnedComebackNudgeService({
    SmartPinnedRecommenderService? recommender,
    DecayTagRetentionTrackerService? retention,
    NudgeFatigueDetectorService? fatigue,
  })  : _recommender = recommender ?? SmartPinnedRecommenderService(),
        _retention = retention ?? const DecayTagRetentionTrackerService(),
        _fatigue = fatigue ?? NudgeFatigueDetectorService.instance;

  static final PinnedComebackNudgeService instance =
      PinnedComebackNudgeService();

  final SmartPinnedRecommenderService _recommender;
  final DecayTagRetentionTrackerService _retention;
  final NudgeFatigueDetectorService _fatigue;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _pluginInitialized = false;
  bool _checking = false;
  static const _lastKey = 'pinned_comeback_nudge_last';

  Future<void> start() async {
    WidgetsBinding.instance.addObserver(this);
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      _scheduleCheck();
    }
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleCheck();
    }
  }

  void _scheduleCheck() {
    Future.delayed(const Duration(seconds: 5), _maybeNudge);
  }

  Future<void> _maybeNudge() async {
    if (_checking) return;
    _checking = true;
    try {
      final prefs = await PreferencesService.getInstance();
      final lastMillis = prefs.getInt(_lastKey);
      if (lastMillis != null &&
          DateTime.now().difference(
                DateTime.fromMillisecondsSinceEpoch(lastMillis),
              ) <
              const Duration(hours: 24)) {
        return;
      }

      final item = await _recommender.recommendNext();
      if (item == null) return;
      if (!await _shouldNudge(item)) return;

      final shown = await InAppNudgeService.show(
        title: 'Continue learning',
        message: 'You have pinned content waiting to review.',
      );
      if (!shown) {
        await _showNotification();
      }
      await prefs.setInt(_lastKey, DateTime.now().millisecondsSinceEpoch);
    } finally {
      _checking = false;
    }
  }

  Future<bool> _shouldNudge(PinnedLearningItem item) async {
    if (await _fatigue.isFatigued(item)) return false;
    if (item.lastSeen != null &&
        DateTime.now().difference(
              DateTime.fromMillisecondsSinceEpoch(item.lastSeen!),
            ) <=
            const Duration(days: 7)) {
      return false;
    }
    if (!await _hasHighDecay(item)) return false;
    return true;
  }

  Future<bool> _hasHighDecay(PinnedLearningItem item) async {
    final tags = <String>[];
    if (item.type == 'pack') {
      final tpl = await PackLibraryService.instance.getById(item.id);
      if (tpl != null) {
        tags.addAll(tpl.tags.map((e) => e.trim().toLowerCase()));
      }
    } else if (item.type == 'lesson') {
      await MiniLessonLibraryService.instance.loadAll();
      final lesson = MiniLessonLibraryService.instance.getById(item.id);
      if (lesson != null) {
        tags.addAll(lesson.tags.map((e) => e.trim().toLowerCase()));
      }
    }
    for (final t in tags) {
      final days = await _retention.getDecayScore(t);
      if (days > 30) return true;
    }
    return false;
  }

  Future<void> _showNotification() async {
    if (!_pluginInitialized) {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
      );
      _pluginInitialized = true;
    }
    await _plugin.show(
      904,
      'Come back to training',
      'You have pinned content getting rusty.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'pinned_comeback',
          'Pinned Comeback',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
