import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/theory_cluster_summary.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/theory_goal_recommender.dart';
import 'package:poker_analyzer/services/tag_mastery_service.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:poker_analyzer/services/theory_lesson_progress_tracker.dart';

class _FakeMasteryService extends TagMasteryService {
  final Map<String, double> _map;
  _FakeMasteryService(this._map)
    : super(logs: SessionLogService(sessions: TrainingSessionService()));

  @override
  Future<Map<String, double>> computeMastery({bool force = false}) async =>
      _map;
}

class _FakeTracker extends TheoryLessonProgressTracker {
  final Map<TheoryClusterSummary, double> _progress;
  const _FakeTracker(this._progress);

  @override
  Future<double> progressForCluster(
    TheoryClusterSummary cluster,
    Map<String, TheoryMiniLessonNode> lessons,
  ) async {
    return _progress[cluster] ?? 0.0;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('recommends cluster and tag goals', () async {
    const cluster = TheoryClusterSummary(
      size: 2,
      entryPointIds: ['l1'],
      sharedTags: {'preflop'},
    );
    final lessons = <String, TheoryMiniLessonNode>{
      'l1': const TheoryMiniLessonNode(
        id: 'l1',
        title: 'L1',
        content: '',
        tags: ['preflop'],
      ),
      'l2': const TheoryMiniLessonNode(
        id: 'l2',
        title: 'L2',
        content: '',
        tags: ['preflop'],
      ),
    };

    const tracker = _FakeTracker({cluster: 0.3});
    final mastery = _FakeMasteryService({'cbet': 0.4});

    final rec = TheoryGoalRecommender(progress: tracker, mastery: mastery);
    final goals = await rec.recommend(clusters: [cluster], lessons: lessons);

    expect(goals.length, 2);
    expect(goals.first.tagOrCluster, 'preflop');
    expect(goals.last.tagOrCluster, 'cbet');
  });
}
