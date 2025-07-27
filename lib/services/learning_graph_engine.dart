import 'session_log_service.dart';
import 'training_session_service.dart';
import 'learning_path_graph_orchestrator.dart';
import 'path_map_engine.dart';
import 'training_path_progress_service_v2.dart';
import '../models/learning_path_node.dart';

/// Coordinates loading and traversal of the adaptive learning path graph.
class LearningPathEngine {
  final LearningPathGraphOrchestrator orchestrator;
  final TrainingPathProgressServiceV2 progress;
  PathMapEngine? _engine;

  LearningPathEngine({
    LearningPathGraphOrchestrator? orchestrator,
    TrainingPathProgressServiceV2? progress,
  })  : orchestrator = orchestrator ?? LearningPathGraphOrchestrator(),
        progress = progress ??
            TrainingPathProgressServiceV2(
              logs: SessionLogService(sessions: TrainingSessionService()),
            );

  static final LearningPathEngine instance = LearningPathEngine();

  /// Loads the active profile graph and prepares for traversal.
  Future<void> initialize() async {
    final nodes = await orchestrator.loadGraph();
    _engine = PathMapEngine(progress: progress);
    await _engine!.loadNodes(nodes);
  }

  /// Returns the node currently in focus.
  LearningPathNode? getCurrentNode() => _engine?.getCurrentNode();

  /// Advances through branch [label] from the current node.
  Future<void> applyBranchChoice(String label) async {
    await _engine?.applyChoice(label);
  }

  /// Marks [nodeId] as completed and moves forward if applicable.
  Future<void> markStageCompleted(String nodeId) async {
    await _engine?.markCompleted(nodeId);
  }

  /// Returns the next node that should be presented to the user.
  LearningPathNode? getNextNode() => _engine?.getNextNode();
}
