
import '../models/learning_path_node.dart';
import 'learning_graph_engine.dart';
import 'smart_weak_review_planner.dart';
import 'theory_booster_injector.dart';
import 'smart_mini_booster_planner.dart';
import 'mini_lesson_booster_engine.dart';
import 'mini_lesson_library_service.dart';
import 'mini_lesson_scheduler.dart';
import 'theory_reinforcement_log_service.dart';
import 'weakness_cluster_engine.dart';
import 'tag_mastery_service.dart';
import 'theory_booster_reinjection_policy.dart';
import 'theory_pack_library_service.dart';
import 'smart_booster_summary_engine.dart';
import 'session_log_service.dart';
import 'training_session_service.dart';
import '../utils/app_logger.dart';

/// Background service that injects weak theory lessons before the next node.
class AutoTheoryReviewEngine {
  final LearningPathEngine engine;
  final SmartWeakReviewPlanner planner;
  final TheoryBoosterInjector injector;
  final SmartMiniBoosterPlanner miniPlanner;
  final MiniLessonBoosterEngine miniInjector;
  final MiniLessonScheduler scheduler;
  final WeaknessClusterEngine clusterEngine;
  final TagMasteryService masteryService;
  final TheoryBoosterReinjectionPolicy reinjectionPolicy;
  final TheoryPackLibraryService library;
  final SmartBoosterSummaryEngine summaryEngine;

  AutoTheoryReviewEngine({
    LearningPathEngine? engine,
    SmartWeakReviewPlanner? planner,
    TheoryBoosterInjector? injector,
    SmartMiniBoosterPlanner? miniPlanner,
    MiniLessonBoosterEngine? miniInjector,
    MiniLessonScheduler? scheduler,
    WeaknessClusterEngine? clusterEngine,
    TagMasteryService? masteryService,
    TheoryBoosterReinjectionPolicy? reinjectionPolicy,
    TheoryPackLibraryService? library,
    SmartBoosterSummaryEngine? summaryEngine,
  })  : engine = engine ?? LearningPathEngine.instance,
        planner = planner ?? SmartWeakReviewPlanner.instance,
        injector = injector ?? TheoryBoosterInjector.instance,
        miniPlanner = miniPlanner ?? SmartMiniBoosterPlanner.instance,
        miniInjector = miniInjector ?? const MiniLessonBoosterEngine(),
        scheduler = scheduler ?? const MiniLessonScheduler(),
        clusterEngine = clusterEngine ?? const WeaknessClusterEngine(),
        masteryService = masteryService ??
            TagMasteryService(
              logs: SessionLogService(sessions: TrainingSessionService()),
            ),
        reinjectionPolicy =
            reinjectionPolicy ?? TheoryBoosterReinjectionPolicy.instance,
        library = library ?? TheoryPackLibraryService.instance,
        summaryEngine = summaryEngine ?? const SmartBoosterSummaryEngine();

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
        final nodes = engine.engine?.allNodes ?? [];
        final byId = {for (final n in nodes) n.id: n};
        final toInject = <String>[];
        for (final id in candidates.take(max)) {
          if (!byId.containsKey(id)) {
            toInject.add(id);
          }
        }
        if (toInject.isNotEmpty) {
          await injector.injectBefore(current.id, toInject);
          for (final id in toInject) {
            await TheoryReinforcementLogService.instance
                .logInjection(id, 'standard', 'auto');
          }
        }
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
          final nodes = engine.engine?.allNodes ?? [];
          if (nodes.any((n) => n.id == id)) continue;
          await miniInjector.injectBefore(current.id, mini.tags, max: 1);
          await TheoryReinforcementLogService.instance
              .logInjection(id, 'mini', 'auto');
        }
      }
    } catch (e, stack) {
      AppLogger.error('AutoTheoryReviewEngine error', e, stack);
    } finally {
      _lastRun = DateTime.now();
    }
  }

  /// Returns booster ids ranked by relevance to [recentWeakTags].
  /// Candidates without tag overlap or failing reinjection policy are skipped.
  Future<List<String>> getRecommendedBoosters({
    required List<String> recentWeakTags,
    required List<String> candidateBoosters,
  }) async {
    if (recentWeakTags.isEmpty || candidateBoosters.isEmpty) return [];

    await library.loadAll();
    final masteryMap = await masteryService.computeMastery();

    final tagSet = {
      for (final t in recentWeakTags) t.trim().toLowerCase()
    }..removeWhere((e) => e.isEmpty);

    final scored = <_BoosterScore>[];
    for (final id in candidateBoosters) {
      final pack = library.getById(id);
      if (pack == null) continue;
      final tags = {for (final t in pack.tags) t.toLowerCase()};
      if (tags.intersection(tagSet).isEmpty) continue;
      if (!await reinjectionPolicy.shouldReinject(id)) continue;

      final mastery = tags
          .map((t) => masteryMap[t] ?? 1.0)
          .fold<double>(1.0, (a, b) => a < b ? a : b);
      final summary = await summaryEngine.summarize(id);
      scored.add(_BoosterScore(id, mastery, summary.avgDeltaEV));
    }

    scored.sort((a, b) {
      final m = a.mastery.compareTo(b.mastery);
      if (m != 0) return m;
      return b.impact.compareTo(a.impact);
    });
    return [for (final s in scored) s.id];
  }
}

class _BoosterScore {
  final String id;
  final double mastery;
  final double impact;
  const _BoosterScore(this.id, this.mastery, this.impact);
}
