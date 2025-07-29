import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/player_profile.dart';
import 'package:poker_analyzer/models/theory_goal.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/models/theory_lesson_cluster.dart';
import 'package:poker_analyzer/services/adaptive_theory_scheduler.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/theory_goal_engine.dart';
import 'package:poker_analyzer/services/theory_lesson_progress_tracker.dart';
import 'package:poker_analyzer/services/theory_lesson_tag_clusterer.dart';
import 'package:poker_analyzer/services/weak_theory_zone_highlighter.dart';
import 'package:poker_analyzer/services/tag_mastery_service.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:poker_analyzer/services/theory_cluster_summary_service.dart';
import 'package:poker_analyzer/services/theory_goal_recommender.dart';
import 'package:poker_analyzer/services/mini_lesson_progress_tracker.dart';

class _StubLibrary extends MiniLessonLibraryService {
  final List<TheoryMiniLessonNode> items;
  _StubLibrary(this.items) : super._();

  @override
  List<TheoryMiniLessonNode> get all => items;

  @override
  Future<void> loadAll() async {}

  @override
  Future<void> reload() async {}
}

class _StubClusterer extends TheoryLessonTagClusterer {
  final List<TheoryLessonCluster> clusters;
  _StubClusterer(this.clusters);
  @override
  Future<List<TheoryLessonCluster>> clusterLessons() async => clusters;
}

class _FakeGoalEngine extends TheoryGoalEngine {
  final List<TheoryGoal> goals;
  _FakeGoalEngine(this.goals)
      : super(
          recommender: TheoryGoalRecommender(
            mastery: TagMasteryService(
              logs:
                  SessionLogService(sessions: TrainingSessionService()),
            ),
          ),
          clusterer: TheoryLessonTagClusterer(),
          summaryService: TheoryClusterSummaryService(),
          library: MiniLessonLibraryService.instance,
        );

  @override
  Future<List<TheoryGoal>> getActiveGoals({bool autoRefresh = true}) async =>
      goals;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('getNextRecommendedLesson prioritizes goal tags', () async {
    final lessons = [
      const TheoryMiniLessonNode(id: 'l1', title: 'L1', content: '', tags: ['a']),
      const TheoryMiniLessonNode(id: 'l2', title: 'L2', content: '', tags: ['b']),
      const TheoryMiniLessonNode(id: 'l3', title: 'L3', content: '', tags: ['c']),
    ];
    final library = _StubLibrary(lessons);
    final clusterer = _StubClusterer([
      TheoryLessonCluster(lessons: lessons, tags: const {'a', 'b', 'c'}),
    ]);
    final goalEngine = _FakeGoalEngine([
      const TheoryGoal(
        title: 'T',
        description: '',
        tagOrCluster: 'b',
        targetProgress: 0.5,
      ),
    ]);
    final scheduler = AdaptiveTheoryScheduler(
      goalEngine: goalEngine,
      weakZone: const WeakTheoryZoneHighlighter(),
      progress: const TheoryLessonProgressTracker(),
      library: library,
      clusterer: clusterer,
    );
    await MiniLessonProgressTracker.instance.markCompleted('l1');
    final profile = PlayerProfile(
      completedLessonIds: {'l1'},
      tagAccuracy: {'a': 0.9, 'b': 0.4, 'c': 0.8},
    );

    final next = await scheduler.getNextRecommendedLesson(profile);
    expect(next?.id, 'l2');
  });
}
