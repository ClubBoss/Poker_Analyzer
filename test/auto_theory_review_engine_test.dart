import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/auto_theory_review_engine.dart';
import 'package:poker_analyzer/services/learning_graph_engine.dart';
import 'package:poker_analyzer/services/learning_path_graph_orchestrator.dart';
import 'package:poker_analyzer/services/path_map_engine.dart';
import 'package:poker_analyzer/services/smart_weak_review_planner.dart';
import 'package:poker_analyzer/services/theory_booster_injector.dart';
import 'package:poker_analyzer/services/mini_lesson_booster_engine.dart';
import 'package:poker_analyzer/services/smart_mini_booster_planner.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/learning_path_stage_library.dart';
import 'package:poker_analyzer/models/learning_path_stage_model.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
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

class _FakeMiniLibrary implements MiniLessonLibraryService {
  final List<TheoryMiniLessonNode> items;
  _FakeMiniLibrary(this.items);

  @override
  List<TheoryMiniLessonNode> get all => items;

  @override
  TheoryMiniLessonNode? getById(String id) =>
      items.firstWhere((e) => e.id == id, orElse: () => null);

  @override
  Future<void> loadAll() async {}

  @override
  Future<void> reload() async {}

  @override
  List<TheoryMiniLessonNode> findByTags(List<String> tags) {
    final result = <TheoryMiniLessonNode>[];
    for (final t in tags) {
      result.addAll(items.where((e) => e.tags.contains(t)));
    }
    return result;
  }

  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) =>
      findByTags(tags.toList());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('runAutoReviewIfNeeded injects nodes', () async {
    SharedPreferences.setMockInitialValues({
      'learning_path_node_history':
          '{"t1":{"nodeId":"t1","firstSeen":"2024-01-01T00:00:00.000","completedAt":"2024-01-01T00:00:00.000"}}',
    });

    final start = TrainingStageNode(id: 'start', nextIds: ['end']);
    final end = TrainingStageNode(id: 'end');
    final review = TheoryLessonNode(
      id: 't1',
      title: 'T',
      content: '',
      nextIds: [],
    );

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
    final startNode = nodes.whereType<StageNode>().firstWhere(
      (n) => n.id == 'start',
    );
    expect(startNode.nextIds.first, 't1');
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('theory_reinforcement_logs')!;
    final list = jsonDecode(raw) as List;
    expect(list.length, 1);
    final data = list.first as Map<String, dynamic>;
    expect(data['id'], 't1');
    expect(data['type'], 'standard');
    expect(data['source'], 'auto');
  });

  test('runAutoReviewIfNeeded injects mini lessons', () async {
    SharedPreferences.setMockInitialValues({});

    final start = TrainingStageNode(id: 'start', nextIds: ['end']);
    final end = TrainingStageNode(id: 'end');

    final orch = _FakeOrchestrator([start, end], [start, end]);
    final progress = _FakeProgress({'start'});
    final engine = LearningPathEngine(orchestrator: orch, progress: progress);
    final injector = TheoryBoosterInjector(engine: engine, orchestrator: orch);
    final planner = SmartWeakReviewPlanner(orchestrator: orch);

    LearningPathStageLibrary.instance.clear();
    LearningPathStageLibrary.instance.add(
      const LearningPathStageModel(
        id: 'start',
        title: 'Start',
        description: '',
        packId: 'p1',
        requiredAccuracy: 80,
        minHands: 10,
        tags: ['mini'],
      ),
    );

    final mini = TheoryMiniLessonNode(
      id: 'm1',
      title: 'Mini',
      content: '',
      tags: const ['mini'],
      nextIds: const [],
    );
    final miniLibrary = _FakeMiniLibrary([mini]);
    final miniInjector = MiniLessonBoosterEngine(
      engine: engine,
      library: miniLibrary,
    );
    final miniPlanner = SmartMiniBoosterPlanner(
      engine: engine,
      library: miniLibrary,
      stageLibrary: LearningPathStageLibrary.instance,
    );

    final auto = AutoTheoryReviewEngine(
      engine: engine,
      planner: planner,
      injector: injector,
      miniPlanner: miniPlanner,
      miniInjector: miniInjector,
    );

    await engine.initialize();
    await auto.runAutoReviewIfNeeded(throttle: Duration.zero);

    final nodes = engine.engine!.allNodes;
    expect(nodes.any((n) => n is TheoryMiniLessonNode && n.id == 'm1'), isTrue);
    final startNode = nodes.whereType<StageNode>().firstWhere(
      (n) => n.id == 'start',
    );
    expect(startNode.nextIds.first, 'm1');
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('theory_reinforcement_logs')!;
    final list = jsonDecode(raw) as List;
    expect(list.length, 1);
    final data = list.first as Map<String, dynamic>;
    expect(data['id'], 'm1');
    expect(data['type'], 'mini');
    expect(data['source'], 'auto');
  });
}
