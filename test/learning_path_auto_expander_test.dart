import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/learning_path_node.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/learning_graph_engine.dart';
import 'package:poker_analyzer/services/learning_path_graph_orchestrator.dart';
import 'package:poker_analyzer/services/training_path_progress_service_v2.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/learning_path_auto_expander.dart';
import 'package:poker_analyzer/services/learning_path_node_history.dart';
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
  List<TheoryMiniLessonNode> findByTags(List<String> tags) => const [];
  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) => const [];
  @override
  List<String> linkedPacksFor(String lessonId) => const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('auto expands mini lesson chain on completion', () async {
    SharedPreferences.setMockInitialValues({});
    final a = TheoryMiniLessonNode(id: 'a', title: 'A', content: '', nextIds: const ['b']);
    final orch = _FakeOrchestrator([a]);
    final progress = _FakeProgress({});
    final library = _FakeLibrary([
      a,
      TheoryMiniLessonNode(id: 'b', title: 'B', content: '', nextIds: const ['c']),
      TheoryMiniLessonNode(id: 'c', title: 'C', content: '', nextIds: const []),
    ]);
    final expander = LearningPathAutoExpander(library: library);
    final engine = LearningPathEngine(
      orchestrator: orch,
      progress: progress,
      autoExpander: expander,
    );

    await engine.initialize();
    expect(engine.getCurrentNode()!.id, 'a');
    await engine.markStageCompleted('a');
    expect(engine.getCurrentNode()!.id, 'b');
    final nodes = engine.engine!.allNodes;
    expect(nodes.any((n) => n.id == 'c'), isTrue);
    expect(
      LearningPathNodeHistory.instance.getAutoInjectedIds(),
      containsAll(['b', 'c']),
    );

    final engine2 = LearningPathEngine(
      orchestrator: orch,
      progress: progress,
      autoExpander: expander,
    );
    await engine2.initialize();
    final nodes2 = engine2.engine!.allNodes;
    expect(nodes2.any((n) => n.id == 'b'), isTrue);
    expect(nodes2.any((n) => n.id == 'c'), isTrue);
  });
}
