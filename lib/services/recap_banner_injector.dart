import 'dart:async';

import 'package:flutter/widgets.dart';

import '../models/theory_mini_lesson_node.dart';
import 'recap_opportunity_detector.dart';
import 'smart_recap_suggestion_engine.dart';
import 'recap_fatigue_evaluator.dart';
import 'smart_recap_banner_controller.dart';
import 'training_session_service.dart';

/// Injects [SmartRecapSuggestionBanner] when new recap suggestions arrive.
class RecapBannerInjector {
  final SmartRecapSuggestionEngine engine;
  final RecapOpportunityDetector detector;
  final RecapFatigueEvaluator fatigue;
  final SmartRecapBannerController controller;
  final TrainingSessionService sessions;

  RecapBannerInjector({
    SmartRecapSuggestionEngine? engine,
    RecapOpportunityDetector? detector,
    RecapFatigueEvaluator? fatigue,
    required this.controller,
    required this.sessions,
  }) : engine = engine ?? SmartRecapSuggestionEngine.instance,
       detector = detector ?? RecapOpportunityDetector.instance,
       fatigue = fatigue ?? RecapFatigueEvaluator.instance;

  StreamSubscription<TheoryMiniLessonNode>? _sub;

  /// Begins listening to [SmartRecapSuggestionEngine.nextRecap].
  Future<void> start() async {
    await engine.start();
    _sub?.cancel();
    _sub = engine.nextRecap.listen(_maybeInject);
  }

  /// Stops listening and disposes resources.
  Future<void> dispose() async {
    await _sub?.cancel();
  }

  bool _modalOpen() => navigatorKey.currentState?.canPop() ?? false;

  bool _inSession() => sessions.currentSession != null && !sessions.isCompleted;

  Future<void> _maybeInject(TheoryMiniLessonNode lesson) async {
    if (_modalOpen() || _inSession() || controller.shouldShowBanner()) return;
    if (!await detector.isGoodRecapMoment()) return;
    if (await fatigue.isFatigued(lesson.id)) return;
    await controller.triggerBannerIfNeeded(lesson);
  }
}
