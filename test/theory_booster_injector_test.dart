import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/theory_booster_injector.dart';
import 'package:poker_analyzer/services/learning_graph_engine.dart';
import 'package:poker_analyzer/services/path_map_engine.dart';
import 'package:poker_analyzer/services/learning_path_graph_orchestrator.dart';
import 'package:poker_analyzer/services/training_path_progress_service_v2.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('injectBefore logs inserted nodes', () async {
    SharedPreferences.setMockInitialValues({});
    final start = TrainingStageNode(id: 'start', nextIds: ['end']);
    final end = TrainingStageNode(id: 'end');
    final review =
        TheoryLessonNode(id: 't1', title: 'T', content: '', nextIds: []);

    final orch = _FakeOrchestrator([start, end, review]);
    final progress = _FakeProgress({'start'});
    final engine = LearningPathEngine(orchestrator: orch, progress: progress);
    final injector = TheoryBoosterInjector(engine: engine, orchestrator: orch);

    await engine.initialize();
    await injector.injectBefore('end', ['t1']);

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('theory_reinforcement_logs')!;
    final list = jsonDecode(raw) as List;
    expect(list.length, 1);
    final data = list.first as Map<String, dynamic>;
    expect(data['id'], 't1');
    expect(data['type'], 'standard');
    expect(data['source'], 'auto');
  });
}
