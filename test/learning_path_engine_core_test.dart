import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/learning_path_node.dart';
import 'package:poker_analyzer/services/graph_path_template_parser.dart';
import 'package:poker_analyzer/services/learning_graph_engine.dart';
import 'package:poker_analyzer/services/learning_path_graph_orchestrator.dart';
import 'package:poker_analyzer/services/training_path_progress_service_v2.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:poker_analyzer/models/session_log.dart';

class _FakeOrchestrator extends LearningPathGraphOrchestrator {
  final List<LearningPathNode> _nodes;
  _FakeOrchestrator(this._nodes);
  @override
  Future<List<LearningPathNode>> loadGraph() async => _nodes;
}

class _FakeLogService extends SessionLogService {
  _FakeLogService() : super(sessions: TrainingSessionService());
  @override
  Future<void> load() async {}
  @override
  List<SessionLog> get logs => [];
}

class _FakeProgress extends TrainingPathProgressServiceV2 {
  final Set<String> completed = {};
  _FakeProgress() : super(logs: _FakeLogService());
  @override
  Future<void> loadProgress(String pathId) async {}
  @override
  Future<void> markStageCompleted(String stageId, double accuracy) async {
    completed.add(stageId);
  }
  @override
  bool isStageUnlocked(String stageId) => true;
  @override
  bool getStageCompletion(String stageId) => completed.contains(stageId);
  @override
  double getStageAccuracy(String stageId) => 0.0;
  @override
  int getStageHands(String stageId) => 0;
  @override
  List<String> unlockedStageIds() => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const yaml = '''
nodes:
  - type: stage
    id: start
    next: [branch]
  - type: branch
    id: branch
    prompt: choose
    branches:
      A: a
      B: b
  - type: stage
    id: a
    next: [end]
  - type: stage
    id: b
    next: [end]
  - type: stage
    id: end
''';

  late List<LearningPathNode> nodes;

  setUpAll(() async {
    final parser = GraphPathTemplateParser();
    nodes = await parser.parseFromYaml(yaml);
  });

  test('initialize loads nodes and sets first node', () async {
    final engine = LearningPathEngine(
      orchestrator: _FakeOrchestrator(nodes),
      progress: _FakeProgress(),
    );
    await engine.initialize();
    expect(engine.getCurrentNode()!.id, 'start');
  });

  test('branch choice moves to selected branch', () async {
    final engine = LearningPathEngine(
      orchestrator: _FakeOrchestrator(nodes),
      progress: _FakeProgress(),
    );
    await engine.initialize();
    await engine.markStageCompleted('start');
    await engine.applyBranchChoice('A');
    expect(engine.getCurrentNode()!.id, 'a');
  });

  test('markStageCompleted advances to next node', () async {
    final engine = LearningPathEngine(
      orchestrator: _FakeOrchestrator(nodes),
      progress: _FakeProgress(),
    );
    await engine.initialize();
    await engine.markStageCompleted('start');
    await engine.applyBranchChoice('A');
    await engine.markStageCompleted('a');
    expect(engine.getCurrentNode()!.id, 'end');
    expect(engine.getNextNode(), isNull);
  });
}
