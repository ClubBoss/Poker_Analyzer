import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../models/theory_mini_lesson_node.dart';
import 'recap_opportunity_detector.dart';
import 'smart_theory_recap_engine.dart';
import 'theory_recap_suppression_engine.dart';
import 'smart_theory_recap_dismissal_memory.dart';
import 'recap_fatigue_evaluator.dart';
import 'training_session_service.dart';

/// Controls when the [SmartRecapSuggestionBanner] should be visible.
class SmartRecapBannerController extends ChangeNotifier {
  final RecapOpportunityDetector detector;
  final SmartTheoryRecapEngine engine;
  final TheoryRecapSuppressionEngine suppression;
  final SmartTheoryRecapDismissalMemory dismissal;
  final RecapFatigueEvaluator fatigue;
  final TrainingSessionService sessions;

  SmartRecapBannerController({
    RecapOpportunityDetector? detector,
    SmartTheoryRecapEngine? engine,
    TheoryRecapSuppressionEngine? suppression,
    SmartTheoryRecapDismissalMemory? dismissal,
    RecapFatigueEvaluator? fatigue,
    required this.sessions,
  }) : detector = detector ?? RecapOpportunityDetector.instance,
       engine = engine ?? SmartTheoryRecapEngine.instance,
       suppression = suppression ?? TheoryRecapSuppressionEngine.instance,
       dismissal = dismissal ?? SmartTheoryRecapDismissalMemory.instance,
       fatigue = fatigue ?? RecapFatigueEvaluator.instance;

  static const _lastKey = 'smart_recap_banner_last';
  TheoryMiniLessonNode? _lesson;
  TheoryMiniLessonNode? _queued;
  bool _visible = false;
  Timer? _timer;

  /// Periodically checks if banner should be shown.
  Future<void> start({Duration interval = const Duration(minutes: 5)}) async {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => triggerBannerIfNeeded());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool shouldShowBanner() => _visible && _lesson != null;

  TheoryMiniLessonNode? getPendingLesson() => _lesson;

  Future<DateTime?> _lastShown() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_lastKey);
    return str == null ? null : DateTime.tryParse(str);
  }

  Future<void> _markShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastKey, DateTime.now().toIso8601String());
  }

  bool _appInForeground() =>
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  bool _noActiveDialog() => !(navigatorKey.currentState?.canPop() ?? false);

  bool _notInSession() =>
      sessions.currentSession == null || sessions.isCompleted;

  Future<void> triggerBannerIfNeeded([TheoryMiniLessonNode? lesson]) async {
    if (!_appInForeground() || !_noActiveDialog() || !_notInSession()) return;
    if (!await detector.isGoodRecapMoment()) return;
    final last = await _lastShown();
    if (last != null &&
        DateTime.now().difference(last) < const Duration(hours: 6)) {
      return;
    }
    final l = lesson ?? _queued ?? await engine.getNextRecap();
    if (l == null) return;
    if (await fatigue.isFatigued(l.id)) return;
    if (await suppression.shouldSuppress(
      lessonId: l.id,
      trigger: 'banner',
    )) {
      return;
    }
    if (await dismissal.shouldThrottle('lesson:${l.id}')) return;
    _lesson = l;
    _queued = null;
    _visible = true;
    await _markShown();
    notifyListeners();
  }

  /// Queues [lesson] to be shown later when [triggerBannerIfNeeded] runs.
  Future<void> queueBannerFor(TheoryMiniLessonNode lesson) async {
    if (_lesson?.id == lesson.id) return;
    _queued = lesson;
  }

  /// Shows the banner for a specific [lesson] without running selection logic.
  Future<void> showManually(TheoryMiniLessonNode lesson) async {
    if (_visible && _lesson?.id == lesson.id) return;
    _lesson = lesson;
    _visible = true;
    await _markShown();
    notifyListeners();
  }

  /// Hides the banner and optionally registers a dismissal.
  Future<void> dismiss({bool recordDismissal = false}) async {
    if (!_visible) return;
    if (recordDismissal && _lesson != null) {
      await dismissal.registerDismissal('lesson:${_lesson!.id}');
    }
    _lesson = null;
    _visible = false;
    notifyListeners();
  }
}
