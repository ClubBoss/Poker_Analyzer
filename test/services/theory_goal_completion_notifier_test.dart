import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/theory_goal.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/theory_goal_completion_notifier.dart';
import 'package:poker_analyzer/services/theory_goal_engine.dart';
import 'package:poker_analyzer/services/theory_goal_recommender.dart';
import 'package:poker_analyzer/services/theory_lesson_tag_clusterer.dart';
import 'package:poker_analyzer/services/theory_cluster_summary_service.dart';
import 'package:poker_analyzer/services/mini_lesson_progress_tracker.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/tag_mastery_service.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:poker_analyzer/models/theory_cluster_summary.dart';
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

  test('notifies when goal is completed', () async {
    SharedPreferences.setMockInitialValues({});
    final library = _StubLibrary([
      const TheoryMiniLessonNode(
        id: 'l1',
        title: 'L1',
        content: '',
        tags: ['t'],
      ),
    ]);
    final goal = const TheoryGoal(
      title: 'G',
      description: 'D',
      tagOrCluster: 't',
      targetProgress: 1.0,
    );
    final engine = TheoryGoalEngine(
      recommender: _FakeRecommender([goal]),
      clusterer: _StubClusterer(const []),
      library: library,
      summaryService: TheoryClusterSummaryService(),
    );

    await engine.refreshGoals();

    bool fired = false;
    final notifier = TheoryGoalCompletionNotifier(
      tracker: MiniLessonProgressTracker.instance,
      engine: engine,
    );
    notifier.setOnGoalCompleted((g) => fired = true);

    await MiniLessonProgressTracker.instance.markCompleted('l1');
    await Future.delayed(Duration.zero);

    expect(fired, isTrue);
    final remaining = await engine.getActiveGoals(autoRefresh: false);
    expect(remaining, isEmpty);
    await notifier.dispose();
  });
}
