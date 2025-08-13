import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/mini_lesson_booster_engine.dart';
import 'package:poker_analyzer/services/learning_graph_engine.dart';
import 'package:poker_analyzer/services/path_map_engine.dart';
import 'package:poker_analyzer/models/learning_path_node.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/learning_path_graph_orchestrator.dart';
import 'package:poker_analyzer/services/training_path_progress_service_v2.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('injectBefore inserts mini lessons', () async {
    final start = TrainingStageNode(id: 'start', nextIds: ['end']);
    final end = TrainingStageNode(id: 'end');

    final orch = _FakeOrchestrator([start, end]);
    final progress = _FakeProgress({'start'});
    final engine = LearningPathEngine(orchestrator: orch, progress: progress);
    final mini = TheoryMiniLessonNode(
      id: 'm1',
      title: 'Mini',
      content: '',
      tags: const ['tag'],
      nextIds: const [],
    );
    final library = _FakeLibrary([mini]);
    final booster = MiniLessonBoosterEngine(engine: engine, library: library);

    await engine.initialize();
    await booster.injectBefore('end', ['tag']);

    final nodes = engine.engine!.allNodes;
    expect(nodes.any((n) => n is TheoryMiniLessonNode && n.id == 'm1'), isTrue);
    final startNode =
        nodes.whereType<StageNode>().firstWhere((n) => n.id == 'start');
    expect(startNode.nextIds.first, 'm1');
  });

  test('injectBefore respects max parameter', () async {
    final start = TrainingStageNode(id: 'start', nextIds: ['end']);
    final end = TrainingStageNode(id: 'end');

    final orch = _FakeOrchestrator([start, end]);
    final progress = _FakeProgress({'start'});
    final engine = LearningPathEngine(orchestrator: orch, progress: progress);
    final mini1 = TheoryMiniLessonNode(
      id: 'm1',
      title: 'Mini1',
      content: '',
      tags: const ['tag'],
      nextIds: const [],
    );
    final mini2 = TheoryMiniLessonNode(
      id: 'm2',
      title: 'Mini2',
      content: '',
      tags: const ['tag'],
      nextIds: const [],
    );
    final library = _FakeLibrary([mini1, mini2]);
    final booster = MiniLessonBoosterEngine(engine: engine, library: library);

    await engine.initialize();
    await booster.injectBefore('end', ['tag'], max: 1);

    final minis =
        engine.engine!.allNodes.whereType<TheoryMiniLessonNode>().toList();
    expect(minis.length, 1);
    expect(minis.first.id, 'm1');
  });
}
