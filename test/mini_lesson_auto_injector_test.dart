import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/learning_path_node.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/learning_graph_engine.dart';
import 'package:poker_analyzer/services/learning_path_graph_orchestrator.dart';
import 'package:poker_analyzer/services/training_path_progress_service_v2.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/mini_lesson_booster_engine.dart';
import 'package:poker_analyzer/services/mini_lesson_auto_injector.dart';
import 'package:poker_analyzer/services/tag_mastery_service.dart';
import 'package:poker_analyzer/services/theory_reinforcement_log_service.dart';

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

class _FakeLibrary implements MiniLessonLibraryService {
  final List<TheoryMiniLessonNode> items;
  _FakeLibrary(this.items);
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

class _FakeMasteryService extends TagMasteryService {
  final Map<String, double> _map;
  _FakeMasteryService(this._map)
      : super(logs: SessionLogService(sessions: TrainingSessionService()));

  @override
  Future<Map<String, double>> computeMastery({bool force = false}) async =>
      _map;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('injectMiniLessonsIfNeeded injects best mini', () async {
    final start = TrainingStageNode(id: 'start', nextIds: ['end']);
    final end = TrainingStageNode(id: 'end');

    final orch = _FakeOrchestrator([start, end]);
    final progress = _FakeProgress({'start'});
    final engine = LearningPathEngine(orchestrator: orch, progress: progress);

    final mini1 = TheoryMiniLessonNode(
      id: 'm1',
      title: 'M1',
      content: '',
      tags: const ['a'],
      nextIds: const [],
    );
    final mini2 = TheoryMiniLessonNode(
      id: 'm2',
      title: 'M2',
      content: '',
      tags: const ['b'],
      nextIds: const [],
    );
    final library = _FakeLibrary([mini1, mini2]);
    final booster = MiniLessonBoosterEngine(engine: engine, library: library);
    final mastery = _FakeMasteryService({'a': 0.2, 'b': 0.8});
    final auto = MiniLessonAutoInjector(
      library: library,
      injector: booster,
      masteryService: mastery,
      engine: engine,
    );

    await engine.initialize();
    await auto.injectMiniLessonsIfNeeded(['a', 'b'], cooldown: Duration.zero);

    final nodes = engine.engine!.allNodes;
    expect(nodes.any((n) => n is TheoryMiniLessonNode && n.id == 'm1'), isTrue);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('theory_reinforcement_logs');
    expect(raw, isNotNull);
    final list = jsonDecode(raw!) as List;
    expect(list.first['id'], 'm1');
  });

  test('injectMiniLessonsIfNeeded respects cooldown', () async {
    final start = TrainingStageNode(id: 'start', nextIds: ['end']);
    final end = TrainingStageNode(id: 'end');

    final orch = _FakeOrchestrator([start, end]);
    final progress = _FakeProgress({'start'});
    final engine = LearningPathEngine(orchestrator: orch, progress: progress);

    final mini = TheoryMiniLessonNode(
      id: 'm1',
      title: 'M1',
      content: '',
      tags: const ['a'],
      nextIds: const [],
    );
    final library = _FakeLibrary([mini]);
    final booster = MiniLessonBoosterEngine(engine: engine, library: library);
    final mastery = _FakeMasteryService({'a': 0.2});
    final logService = TheoryReinforcementLogService.instance;
    final auto = MiniLessonAutoInjector(
      library: library,
      injector: booster,
      masteryService: mastery,
      engine: engine,
      logService: logService,
    );

    await engine.initialize();
    await logService.logInjection('m1', 'mini', 'auto');
    await auto.injectMiniLessonsIfNeeded(['a'], cooldown: Duration(hours: 1));

    final nodes = engine.engine!.allNodes;
    expect(nodes.whereType<TheoryMiniLessonNode>().length, 0);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('theory_reinforcement_logs');
    final list = jsonDecode(raw!) as List;
    // only the initial log entry should exist
    expect(list.length, 1);
  });
}
