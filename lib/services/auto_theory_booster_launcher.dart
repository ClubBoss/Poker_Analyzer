import 'dart:async';

import 'package:flutter/material.dart';

import '../main.dart';
import '../screens/mini_lesson_screen.dart';
import '../models/recap_completion_log.dart';
import 'recap_completion_tracker.dart';
import 'theory_boost_trigger_service.dart';

/// Automatically launches theory boosters after recap completions when warranted.
class AutoTheoryBoosterLauncher {
  final RecapCompletionTracker tracker;
  final TheoryBoostTriggerService trigger;
  final Duration cooldown;

  AutoTheoryBoosterLauncher({
    RecapCompletionTracker? tracker,
    TheoryBoostTriggerService? trigger,
    this.cooldown = const Duration(minutes: 10),
  }) : tracker = tracker ?? RecapCompletionTracker.instance,
       trigger = trigger ?? TheoryBoostTriggerService.instance {
    _sub = this.tracker.onCompletion.listen(_handle);
  }

  static final AutoTheoryBoosterLauncher instance = AutoTheoryBoosterLauncher();

  StreamSubscription<RecapCompletionLog>? _sub;
  DateTime _lastLaunch = DateTime.fromMillisecondsSinceEpoch(0);

  void dispose() {
    _sub?.cancel();
  }

  bool _underCooldown() => DateTime.now().difference(_lastLaunch) < cooldown;

  Future<void> _handle(RecapCompletionLog log) async {
    if (_underCooldown()) return;
    final lesson = await trigger.getBoostCandidate(log.tag);
    if (lesson == null) return;
    final ctx = navigatorKey.currentState?.context;
    if (ctx == null) return;
    _lastLaunch = DateTime.now();
    Navigator.push(
      ctx,
      MaterialPageRoute(builder: (_) => MiniLessonScreen(lesson: lesson)),
    );
  }
}
