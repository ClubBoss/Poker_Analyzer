import 'dart:convert';
import 'package:poker_analyzer/services/preferences_service.dart';


import 'session_log_service.dart';
import 'training_session_service.dart';
import 'learning_path_graph_orchestrator.dart';
import 'path_map_engine.dart';
import 'training_path_progress_service_v2.dart';
import 'learning_path_node_history.dart';
import 'auto_theory_review_engine.dart';
import 'learning_path_level_one_builder_service.dart';
import '../models/learning_path_node.dart';
import '../models/learning_path_session_state.dart';
import '../models/learning_branch_node.dart';
import '../models/theory_lesson_node.dart';
import '../models/theory_mini_lesson_node.dart';

/// Coordinates loading and traversal of the adaptive learning path graph.
class LearningPathEngine {
  final LearningPathGraphOrchestrator orchestrator;
  final TrainingPathProgressServiceV2 progress;
  final LearningPathLevelOneBuilderService levelOneBuilder;
  PathMapEngine? _engine;
  static const _sessionKey = 'learning_path_session';

  /// Exposes the underlying [PathMapEngine] instance for advanced operations.
  PathMapEngine? get engine => _engine;

  LearningPathEngine({
    LearningPathGraphOrchestrator? orchestrator,
    TrainingPathProgressServiceV2? progress,
    LearningPathLevelOneBuilderService? levelOneBuilder,
  })  : orchestrator = orchestrator ?? LearningPathGraphOrchestrator(),
        progress = progress ??
            TrainingPathProgressServiceV2(
              logs: SessionLogService(sessions: TrainingSessionService()),
            ),
        levelOneBuilder =
            levelOneBuilder ?? const LearningPathLevelOneBuilderService();

  static final LearningPathEngine instance = LearningPathEngine();

  /// Loads the active profile graph and prepares for traversal.
  Future<void> initialize() async {
    await LearningPathNodeHistory.instance.load();
    List<LearningPathNode> nodes = await orchestrator.loadGraph();
    if (nodes.isEmpty) {
      nodes = levelOneBuilder.build().cast<LearningPathNode>();
    }
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

  /// Returns all nodes in the active learning path.
  List<LearningPathNode> getAllNodes() => _engine?.allNodes ?? const [];

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
    final prefs = await PreferencesService.getInstance();
    final json = jsonEncode(_engine!.getState().toJson());
    await prefs.setString(_sessionKey, json);
  }

  /// Restores session state from [SharedPreferences] if available.
  Future<void> restoreSession() async {
    final prefs = await PreferencesService.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null || raw.isEmpty) return;
    final map = jsonDecode(raw);
    final state = LearningPathSessionState.fromJson(map);
    await restoreState(state);
  }

  /// Removes any persisted session state.
  Future<void> clearSession() async {
    final prefs = await PreferencesService.getInstance();
    await prefs.remove(_sessionKey);
  }

  /// Removes [nodeId] from the active graph if present.
  Future<void> removeNode(String nodeId) async {
    final mapEngine = _engine;
    if (mapEngine == null) return;

    final nodes = mapEngine.allNodes;
    final byId = {for (final n in nodes) n.id: n};
    final target = byId[nodeId];
    if (target == null) return;

    String? replacement;
    if (target is StageNode) {
      replacement = target.nextIds.isNotEmpty ? target.nextIds.first : null;
    } else if (target is TheoryLessonNode) {
      replacement = target.nextIds.isNotEmpty ? target.nextIds.first : null;
    } else if (target is TheoryMiniLessonNode) {
      replacement = target.nextIds.isNotEmpty ? target.nextIds.first : null;
    }

    LearningPathNode _clone(LearningPathNode node) {
      if (node is LearningBranchNode) {
        final branches = Map<String, String>.from(node.branches);
        branches.updateAll((key, value) => value == nodeId ? (replacement ?? value) : value);
        branches.removeWhere((key, value) => value.isEmpty);
        return LearningBranchNode(
          id: node.id,
          prompt: node.prompt,
          branches: branches,
          recoveredFromMistake: node.recoveredFromMistake,
        );
      } else if (node is TrainingStageNode) {
        final next = [for (final n in node.nextIds) if (n != nodeId) n];
        if (replacement != null) {
          for (var i = 0; i < node.nextIds.length; i++) {
            if (node.nextIds[i] == nodeId) next.insert(i, replacement!);
          }
        }
        return TrainingStageNode(
          id: node.id,
          nextIds: next,
          dependsOn: List<String>.from(node.dependsOn),
          recoveredFromMistake: node.recoveredFromMistake,
        );
      } else if (node is TheoryStageNode) {
        final next = [for (final n in node.nextIds) if (n != nodeId) n];
        if (replacement != null) {
          for (var i = 0; i < node.nextIds.length; i++) {
            if (node.nextIds[i] == nodeId) next.insert(i, replacement!);
          }
        }
        return TheoryStageNode(
          id: node.id,
          nextIds: next,
          dependsOn: List<String>.from(node.dependsOn),
          recoveredFromMistake: node.recoveredFromMistake,
        );
      } else if (node is TheoryLessonNode) {
        final next = [for (final n in node.nextIds) if (n != nodeId) n];
        if (replacement != null) {
          for (var i = 0; i < node.nextIds.length; i++) {
            if (node.nextIds[i] == nodeId) next.insert(i, replacement!);
          }
        }
        return TheoryLessonNode(
          id: node.id,
          refId: node.refId,
          title: node.title,
          content: node.content,
          nextIds: next,
          recoveredFromMistake: node.recoveredFromMistake,
        );
      } else if (node is TheoryMiniLessonNode) {
        final next = [for (final n in node.nextIds) if (n != nodeId) n];
        if (replacement != null) {
          for (var i = 0; i < node.nextIds.length; i++) {
            if (node.nextIds[i] == nodeId) next.insert(i, replacement!);
          }
        }
        return TheoryMiniLessonNode(
          id: node.id,
          refId: node.refId,
          title: node.title,
          content: node.content,
          tags: List<String>.from(node.tags),
          nextIds: next,
          recoveredFromMistake: node.recoveredFromMistake,
        );
      }
      return node;
    }

    final updated = <LearningPathNode>[for (final n in nodes) if (n.id != nodeId) _clone(n)];

    final state = mapEngine.getState();
    final branchChoices = Map<String, String>.from(state.branchChoices)
      ..remove(nodeId);
    final completed = Set<String>.from(state.completedStageIds)..remove(nodeId);
    final current = state.currentNodeId == nodeId ? (replacement ?? '') : state.currentNodeId;
    final newState = LearningPathSessionState(
      currentNodeId: current,
      branchChoices: branchChoices,
      completedStageIds: completed,
    );

    await mapEngine.loadNodes(updated);
    await mapEngine.restoreState(newState);
  }
}
