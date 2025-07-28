import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'session_log_service.dart';
import 'training_session_service.dart';
import 'learning_path_graph_orchestrator.dart';
import 'path_map_engine.dart';
import 'training_path_progress_service_v2.dart';
import 'learning_path_node_history.dart';
import 'auto_theory_review_engine.dart';
import '../models/learning_path_node.dart';
import '../models/learning_path_session_state.dart';

/// Coordinates loading and traversal of the adaptive learning path graph.
class LearningPathEngine {
  final LearningPathGraphOrchestrator orchestrator;
  final TrainingPathProgressServiceV2 progress;
  PathMapEngine? _engine;
  static const _sessionKey = 'learning_path_session';

  /// Exposes the underlying [PathMapEngine] instance for advanced operations.
  PathMapEngine? get engine => _engine;

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
    await LearningPathNodeHistory.instance.load();
    final nodes = await orchestrator.loadGraph();
    _engine = PathMapEngine(progress: progress);
    await _engine!.loadNodes(nodes);
    await restoreSession();
    final current = getCurrentNode();
    if (current != null) {
      await LearningPathNodeHistory.instance.markVisited(current.id);
    }
    await AutoTheoryReviewEngine.instance.runAutoReviewIfNeeded();
  }

  /// Returns the node currently in focus.
  LearningPathNode? getCurrentNode() => _engine?.getCurrentNode();

  /// Advances through branch [label] from the current node.
  Future<void> applyBranchChoice(String label) async {
    await _engine?.applyChoice(label);
    final node = getCurrentNode();
    if (node != null) {
      await LearningPathNodeHistory.instance.markVisited(node.id);
    }
  }

  /// Marks [nodeId] as completed and moves forward if applicable.
  Future<void> markStageCompleted(String nodeId) async {
    await LearningPathNodeHistory.instance.markCompleted(nodeId);
    await _engine?.markCompleted(nodeId);
    final node = getCurrentNode();
    if (node != null) {
      await LearningPathNodeHistory.instance.markVisited(node.id);
    }
  }

  /// Returns the next node that should be presented to the user.
  LearningPathNode? getNextNode() => _engine?.getNextNode();

  /// Returns whether the given [nodeId] was completed at least once.
  bool isCompleted(String nodeId) =>
      LearningPathNodeHistory.instance.isCompleted(nodeId);

  /// Returns a snapshot of the current session state.
  LearningPathSessionState? getSessionState() => _engine?.getState();

  /// Restores engine state from [state].
  Future<void> restoreState(LearningPathSessionState state) async {
    if (_engine != null) {
      await _engine!.restoreState(state);
      final node = getCurrentNode();
      if (node != null) {
        await LearningPathNodeHistory.instance.markVisited(node.id);
      }
    }
  }

  /// Saves current session state to [SharedPreferences].
  Future<void> saveSession() async {
    if (_engine == null) return;
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_engine!.getState().toJson());
    await prefs.setString(_sessionKey, json);
  }

  /// Restores session state from [SharedPreferences] if available.
  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null || raw.isEmpty) return;
    final map = jsonDecode(raw);
    final state = LearningPathSessionState.fromJson(map);
    await restoreState(state);
  }

  /// Removes any persisted session state.
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}
