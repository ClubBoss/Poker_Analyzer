import 'package:flutter/foundation.dart';

import '../models/learning_path_node.dart';
import 'learning_graph_engine.dart';
import 'smart_weak_review_planner.dart';
import 'theory_booster_injector.dart';

/// Background service that injects weak theory lessons before the next node.
class AutoTheoryReviewEngine {
  final LearningPathEngine engine;
  final SmartWeakReviewPlanner planner;
  final TheoryBoosterInjector injector;

  AutoTheoryReviewEngine({
    LearningPathEngine? engine,
    SmartWeakReviewPlanner? planner,
    TheoryBoosterInjector? injector,
  })  : engine = engine ?? LearningPathEngine.instance,
        planner = planner ?? SmartWeakReviewPlanner.instance,
        injector = injector ?? TheoryBoosterInjector.instance;

  static final AutoTheoryReviewEngine instance = AutoTheoryReviewEngine();

  DateTime _lastRun = DateTime.fromMillisecondsSinceEpoch(0);

  /// Loads weak theory nodes and injects them before the current node.
  Future<void> runAutoReviewIfNeeded({
    int max = 3,
    Duration throttle = const Duration(minutes: 30),
  }) async {
    if (DateTime.now().difference(_lastRun) < throttle) return;
    final current = engine.getCurrentNode();
    if (current == null) return;
    try {
      final candidates = await planner.getWeakReviewCandidates();
      if (candidates.isEmpty) return;
      await injector.injectBefore(
        current.id,
        candidates.take(max).toList(),
      );
    } catch (e) {
      debugPrint('AutoTheoryReviewEngine error: $e');
    } finally {
      _lastRun = DateTime.now();
    }
  }
}
