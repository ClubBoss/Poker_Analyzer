import 'auto_theory_review_engine.dart';
import 'learning_graph_engine.dart';
import 'smart_weak_review_planner.dart';
import 'tag_mastery_service.dart';
import 'theory_booster_injector.dart';
import 'theory_reinforcement_log_service.dart';
import 'session_log_service.dart';
import 'training_session_service.dart';

/// Background job that injects high-priority theory boosters before
/// the upcoming node using a personalized priority score.
class SmartReinjectionFlow {
  final AutoTheoryReviewEngine reviewEngine;
  final SmartWeakReviewPlanner weakPlanner;
  final TheoryBoosterInjector injector;
  final TagMasteryService masteryService;
  final TheoryReinforcementLogService logService;
  final LearningPathEngine engine;

  SmartReinjectionFlow({
    AutoTheoryReviewEngine? reviewEngine,
    SmartWeakReviewPlanner? weakPlanner,
    TheoryBoosterInjector? injector,
    TagMasteryService? masteryService,
    TheoryReinforcementLogService? logService,
    LearningPathEngine? engine,
  })  : reviewEngine = reviewEngine ?? AutoTheoryReviewEngine.instance,
        weakPlanner = weakPlanner ?? SmartWeakReviewPlanner.instance,
        injector = injector ?? TheoryBoosterInjector.instance,
        masteryService = masteryService ??
            TagMasteryService(
              logs: SessionLogService(sessions: TrainingSessionService()),
            ),
        logService = logService ?? TheoryReinforcementLogService.instance,
        engine = engine ?? LearningPathEngine.instance;

  static final SmartReinjectionFlow instance = SmartReinjectionFlow();

  DateTime _lastRun = DateTime.fromMillisecondsSinceEpoch(0);

  /// Schedules the highest priority booster before the next node when appropriate.
  Future<void> injectTopReinforcementBeforeNextNode({
    Duration throttle = const Duration(minutes: 30),
    int weakTagCount = 5,
  }) async {
    if (DateTime.now().difference(_lastRun) < throttle) return;
    final recent = await logService.getRecent(within: throttle);
    if (recent.isNotEmpty) return;

    final next = engine.getNextNode();
    if (next == null) return;

    final candidateIds = await weakPlanner.getWeakReviewCandidates();
    if (candidateIds.isEmpty) return;

    final masteryMap = await masteryService.computeMastery();
    final weakTags = masteryMap.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final tags = [for (final e in weakTags.take(weakTagCount)) e.key];

    final ranked = await reviewEngine.getRecommendedBoosters(
      recentWeakTags: tags,
      candidateBoosters: candidateIds,
    );
    if (ranked.isEmpty) return;

    final boosterId = ranked.first;
    await injector.injectBefore(next.id, [boosterId]);
    await logService.logInjection(boosterId, 'standard', 'smart');
    _lastRun = DateTime.now();
  }
}
