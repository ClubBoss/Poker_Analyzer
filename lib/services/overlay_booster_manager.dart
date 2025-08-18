import 'dart:async';

import 'package:flutter/material.dart';
import '../main.dart';
import '../widgets/skill_gap_overlay_banner.dart';
import 'smart_skill_gap_booster_engine.dart';
import '../screens/mini_lesson_screen.dart';
import 'theory_booster_recall_engine.dart';
import 'user_action_logger.dart';
import 'booster_queue_pressure_monitor.dart';
import 'theory_injection_horizon_service.dart';
import 'booster_cooldown_blocker_service.dart';

/// Schedules and displays [SkillGapOverlayBanner] when major theory gaps exist.
class OverlayBoosterManager with WidgetsBindingObserver {
  final SmartSkillGapBoosterEngine engine;
  final Duration cooldown;

  OverlayBoosterManager({
    SmartSkillGapBoosterEngine? engine,
    this.cooldown = const Duration(hours: 6),
  }) : engine = engine ?? const SmartSkillGapBoosterEngine();

  OverlayEntry? _entry;
  DateTime _lastShown = DateTime.fromMillisecondsSinceEpoch(0);
  bool _checking = false;

  /// Returns true if an overlay banner is currently visible.
  bool get isShowing => _entry != null;

  /// Start observing app lifecycle.
  Future<void> start() async {
    WidgetsBinding.instance.addObserver(this);
    await _check();
  }

  /// Stop observing.
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    _remove();
  }

  /// Check for boosters after XP screen.
  Future<void> onAfterXpScreen() async {
    await _check();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _check();
    }
  }

  bool _anotherOverlayActive() =>
      _entry != null || (navigatorKey.currentState?.canPop() ?? false);

  Future<void> _check() async {
    if (_checking || _anotherOverlayActive()) return;
    if (await BoosterQueuePressureMonitor.instance.isOverloaded()) return;
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    if (await BoosterCooldownBlockerService.instance.isCoolingDown(
      'skill_gap',
    )) {
      return;
    }
    if (!await TheoryInjectionHorizonService.instance.canInject(
      'skill_gap',
      minGap: cooldown,
    )) {
      return;
    }
    _checking = true;
    try {
      final lessons = await engine.recommend(max: 1);
      if (lessons.isEmpty) return;
      final lesson = lessons.first;
      final overlay = Overlay.of(ctx);
      void dismiss() {
        _remove();
        BoosterCooldownBlockerService.instance.markDismissed('skill_gap');
      }

      Future<void> open() async {
        _remove();
        await TheoryBoosterRecallEngine.instance.recordLaunch(lesson.id);
        await BoosterCooldownBlockerService.instance.markCompleted('skill_gap');
        await UserActionLogger.instance.logEvent({
          'event': 'skill_gap_overlay.open',
          'lesson': lesson.id,
        });
        await Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => MiniLessonScreen(lesson: lesson)),
        );
      }

      _entry = OverlayEntry(
        builder: (_) => SkillGapOverlayBanner(
          tags: lesson.tags,
          onDismiss: dismiss,
          onOpen: open,
        ),
      );
      overlay.insert(_entry!);
      await TheoryBoosterRecallEngine.instance.recordSuggestion(lesson.id);
      await UserActionLogger.instance.logEvent({
        'event': 'skill_gap_overlay.shown',
        'lesson': lesson.id,
      });
      _lastShown = DateTime.now();
      await TheoryInjectionHorizonService.instance.markInjected('skill_gap');
    } finally {
      _checking = false;
    }
  }

  void _remove() {
    _entry?.remove();
    _entry = null;
  }
}
