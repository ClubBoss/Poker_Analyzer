import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/auto_theory_review_engine.dart';
import 'package:poker_analyzer/services/learning_graph_engine.dart';
import 'package:poker_analyzer/services/learning_path_graph_orchestrator.dart';
import 'package:poker_analyzer/services/path_map_engine.dart';
import 'package:poker_analyzer/services/smart_weak_review_planner.dart';
import 'package:poker_analyzer/services/theory_booster_injector.dart';
import 'package:poker_analyzer/models/learning_branch_node.dart';
import 'package:poker_analyzer/models/learning_path_node.dart';
import 'package:poker_analyzer/models/theory_lesson_node.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeOrchestrator extends LearningPathGraphOrchestrator {
  final List<LearningPathNode> initial;
  final List<LearningPathNode> full;
  var _first = true;
  _FakeOrchestrator(this.initial, this.full);
  @override
  Future<List<LearningPathNode>> loadGraph() async {
    if (_first) {
      _first = false;
      return initial;
    }
    return full;
  }
}

class _FakeProgress extends TrainingPathProgressServiceV2 {
  final Set<String> completed;
  _FakeProgress(this.completed)
      : super(logs: SessionLogService(sessions: TrainingSessionService()));
  @override
  Future<void> loadProgress(String pathId) async {}
  @override
  bool isStageUnlocked(String stageId) => true;
  @override
  bool getStageCompletion(String stageId) => completed.contains(stageId);
  @override
  double getStageAccuracy(String stageId) => 0.0;
  @override
  int getStageHands(String stageId) => 0;
  @override
  Future<void> markStageCompleted(String stageId, double accuracy) async {
    completed.add(stageId);
  }

  @override
  List<String> unlockedStageIds() => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('runAutoReviewIfNeeded injects nodes', () async {
    SharedPreferences.setMockInitialValues({
      'learning_path_node_history':
          '{"t1":{"nodeId":"t1","firstSeen":"2024-01-01T00:00:00.000","completedAt":"2024-01-01T00:00:00.000"}}'
    });

    final start = TrainingStageNode(id: 'start', nextIds: ['end']);
    final end = TrainingStageNode(id: 'end');
    final review =
        TheoryLessonNode(id: 't1', title: 'T', content: '', nextIds: []);

    final orch = _FakeOrchestrator([start, end], [start, end, review]);
    final progress = _FakeProgress({'start'});
    final engine = LearningPathEngine(orchestrator: orch, progress: progress);
    final injector = TheoryBoosterInjector(engine: engine, orchestrator: orch);
    final planner = SmartWeakReviewPlanner(orchestrator: orch);
    final auto = AutoTheoryReviewEngine(
      engine: engine,
      planner: planner,
      injector: injector,
    );

    await engine.initialize();
    await auto.runAutoReviewIfNeeded(max: 1, throttle: Duration.zero);

    final nodes = engine.engine!.allNodes;
    expect(nodes.any((n) => n.id == 't1'), isTrue);
    final startNode =
        nodes.whereType<StageNode>().firstWhere((n) => n.id == 'start');
    expect(startNode.nextIds.first, 't1');
  });
}
