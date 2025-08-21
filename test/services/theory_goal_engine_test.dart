import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/theory_goal_engine.dart';
import 'package:poker_analyzer/models/theory_goal.dart';
import 'package:poker_analyzer/services/theory_goal_recommender.dart';
import 'package:poker_analyzer/services/theory_cluster_summary_service.dart';
import 'package:poker_analyzer/services/theory_lesson_tag_clusterer.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/tag_mastery_service.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/theory_cluster_summary.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/models/theory_lesson_cluster.dart';

class _FakeRecommender extends TheoryGoalRecommender {
  final List<TheoryGoal> goals;
  _FakeRecommender(this.goals)
    : super(
        mastery: TagMasteryService(
          logs: SessionLogService(sessions: TrainingSessionService()),
        ),
      );

  @override
  Future<List<TheoryGoal>> recommend({
    required List<TheoryClusterSummary> clusters,
    required Map<String, TheoryMiniLessonNode> lessons,
  }) async {
    return goals;
  }
}

class _StubClusterer extends TheoryLessonTagClusterer {
  final List<TheoryLessonCluster> clusters;
  _StubClusterer(this.clusters);
  @override
  Future<List<TheoryLessonCluster>> clusterLessons() async => clusters;
}

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('refreshGoals stores unique goals and persists them', () async {
    SharedPreferences.setMockInitialValues({});
    final goals = [
      const TheoryGoal(
        title: 'T1',
        description: 'D1',
        tagOrCluster: 'tag',
        targetProgress: 0.5,
      ),
      const TheoryGoal(
        title: 'T2',
        description: 'D2',
        tagOrCluster: 'tag',
        targetProgress: 0.75,
      ),
    ];
    final engine = TheoryGoalEngine(
      recommender: _FakeRecommender(goals),
      clusterer: _StubClusterer(const []),
      library: _StubLibrary(const []),
      summaryService: TheoryClusterSummaryService(),
    );

    await engine.refreshGoals();
    final active = await engine.getActiveGoals();
    expect(active.length, 1);

    final engine2 = TheoryGoalEngine(
      recommender: _FakeRecommender(const []),
      clusterer: _StubClusterer(const []),
      library: _StubLibrary(const []),
      summaryService: TheoryClusterSummaryService(),
    );
    final loaded = await engine2.getActiveGoals(autoRefresh: false);
    expect(loaded.length, 1);
    expect(loaded.first.title, 'T1');
  });

  test('markCompleted removes goal', () async {
    SharedPreferences.setMockInitialValues({});
    final goal = const TheoryGoal(
      title: 'T',
      description: 'D',
      tagOrCluster: 'x',
      targetProgress: 0.5,
    );
    final engine = TheoryGoalEngine(
      recommender: _FakeRecommender([goal]),
      clusterer: _StubClusterer(const []),
      library: _StubLibrary(const []),
      summaryService: TheoryClusterSummaryService(),
    );

    await engine.refreshGoals();
    await engine.markCompleted('x');
    final active = await engine.getActiveGoals(autoRefresh: false);
    expect(active, isEmpty);
  });
}
