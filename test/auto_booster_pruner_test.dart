import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/auto_booster_pruner.dart';
import 'package:poker_analyzer/services/learning_graph_engine.dart';
import 'package:poker_analyzer/services/learning_path_graph_orchestrator.dart';
import 'package:poker_analyzer/services/path_map_engine.dart';
import 'package:poker_analyzer/services/training_path_progress_service_v2.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:poker_analyzer/services/theory_booster_reinjection_policy.dart';
import 'package:poker_analyzer/models/learning_path_node.dart';
import 'package:poker_analyzer/models/theory_lesson_node.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeOrchestrator extends LearningPathGraphOrchestrator {
  final List<LearningPathNode> nodes;
  _FakeOrchestrator(this.nodes);
  @override
  Future<List<LearningPathNode>> loadGraph() async => nodes;
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

class _FakePolicy extends TheoryBoosterReinjectionPolicy {
  final bool reinject;
  _FakePolicy(this.reinject);
  @override
  Future<bool> shouldReinject(String boosterId) async => reinject;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('pruneLowImpactBoosters removes boosters', () async {
    SharedPreferences.setMockInitialValues({});
    final start = TrainingStageNode(id: 'start', nextIds: ['b1']);
    final booster =
        TheoryLessonNode(id: 'b1', title: 'B1', content: '', nextIds: ['end']);
    final end = TrainingStageNode(id: 'end');

    final orch = _FakeOrchestrator([start, booster, end]);
    final progress = _FakeProgress({'start'});
    final engine = LearningPathEngine(orchestrator: orch, progress: progress);
    final pruner =
        AutoBoosterPruner(engine: engine, policy: _FakePolicy(false));

    await engine.initialize();
    final count = await pruner.pruneLowImpactBoosters(['b1']);

    expect(count, 1);
    final nodes = engine.engine!.allNodes;
    expect(nodes.any((n) => n.id == 'b1'), isFalse);
    final startNode =
        nodes.whereType<StageNode>().firstWhere((n) => n.id == 'start');
    expect(startNode.nextIds.first, 'end');
  });

  test('pruneLowImpactBoosters keeps effective boosters', () async {
    SharedPreferences.setMockInitialValues({});
    final start = TrainingStageNode(id: 'start', nextIds: ['b2']);
    final booster =
        TheoryLessonNode(id: 'b2', title: 'B2', content: '', nextIds: ['end']);
    final end = TrainingStageNode(id: 'end');

    final orch = _FakeOrchestrator([start, booster, end]);
    final progress = _FakeProgress({'start'});
    final engine = LearningPathEngine(orchestrator: orch, progress: progress);
    final pruner = AutoBoosterPruner(engine: engine, policy: _FakePolicy(true));

    await engine.initialize();
    final count = await pruner.pruneLowImpactBoosters(['b2']);

    expect(count, 0);
    final nodes = engine.engine!.allNodes;
    expect(nodes.any((n) => n.id == 'b2'), isTrue);
  });
}
