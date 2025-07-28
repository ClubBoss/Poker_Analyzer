import 'package:flutter/foundation.dart';

import '../models/learning_path_node.dart';
import 'learning_graph_engine.dart';
import 'smart_weak_review_planner.dart';
import 'theory_booster_injector.dart';
import 'smart_mini_booster_planner.dart';
import 'mini_lesson_booster_engine.dart';
import 'mini_lesson_library_service.dart';
import 'mini_lesson_scheduler.dart';

/// Background service that injects weak theory lessons before the next node.
class AutoTheoryReviewEngine {
  final LearningPathEngine engine;
  final SmartWeakReviewPlanner planner;
  final TheoryBoosterInjector injector;
  final SmartMiniBoosterPlanner miniPlanner;
  final MiniLessonBoosterEngine miniInjector;
  final MiniLessonScheduler scheduler;

  AutoTheoryReviewEngine({
    LearningPathEngine? engine,
    SmartWeakReviewPlanner? planner,
    TheoryBoosterInjector? injector,
    SmartMiniBoosterPlanner? miniPlanner,
    MiniLessonBoosterEngine? miniInjector,
    MiniLessonScheduler? scheduler,
  })  : engine = engine ?? LearningPathEngine.instance,
        planner = planner ?? SmartWeakReviewPlanner.instance,
        injector = injector ?? TheoryBoosterInjector.instance,
        miniPlanner = miniPlanner ?? SmartMiniBoosterPlanner.instance,
        miniInjector = miniInjector ?? const MiniLessonBoosterEngine(),
        scheduler = scheduler ?? const MiniLessonScheduler();

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
      final miniIds = await miniPlanner.getRelevantMiniLessons();
      if (candidates.isEmpty && miniIds.isEmpty) return;
      if (candidates.isNotEmpty) {
        await injector.injectBefore(current.id, candidates.take(max).toList());
      }
      if (miniIds.isNotEmpty) {
        final exclude = [for (final n in engine.engine?.allNodes ?? []) n.id];
        final scheduled = await scheduler.schedule(
          miniIds,
          excludeIds: exclude,
        );
        for (final id in scheduled) {
          final mini = MiniLessonLibraryService.instance.getById(id);
          if (mini == null) continue;
          await miniInjector.injectBefore(current.id, mini.tags, max: 1);
        }
      }
    } catch (e) {
      debugPrint('AutoTheoryReviewEngine error: $e');
    } finally {
      _lastRun = DateTime.now();
    }
  }
}
