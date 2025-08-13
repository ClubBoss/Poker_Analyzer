import 'package:collection/collection.dart';

import '../models/learning_branch_node.dart';
import '../models/learning_path_node.dart';
import '../models/stage_type.dart';
import '../models/learning_path_session_state.dart';
import '../models/theory_lesson_node.dart';
import '../models/theory_mini_lesson_node.dart';
import 'learning_path_registry_service.dart';
import 'training_path_progress_service_v2.dart';

/// Base class for stage-based nodes in a learning path graph.
abstract class StageNode implements LearningPathNode {
  /// Identifier of this node.
  @override
  final String id;

  @override
  final bool recoveredFromMistake;

  /// IDs of nodes unlocked after completing this one.
  final List<String> nextIds;

  /// IDs of prerequisite nodes that must be completed before this one.
  final List<String> dependsOn;

  const StageNode({
    required this.id,
    List<String>? nextIds,
    List<String>? dependsOn,
    this.recoveredFromMistake = false,
  })  : nextIds = nextIds ?? const [],
        dependsOn = dependsOn ?? const [];
}

/// Node representing a practice or training stage.
class TrainingStageNode extends StageNode {
  const TrainingStageNode({
    required super.id,
    List<String>? nextIds,
    List<String>? dependsOn,
    bool recoveredFromMistake = false,
  }) : super(
          nextIds: nextIds,
          dependsOn: dependsOn,
          recoveredFromMistake: recoveredFromMistake,
        );
}

/// Node representing a theory stage.
class TheoryStageNode extends StageNode {
  const TheoryStageNode({
    required super.id,
    List<String>? nextIds,
    List<String>? dependsOn,
    bool recoveredFromMistake = false,
  }) : super(
          nextIds: nextIds,
          dependsOn: dependsOn,
          recoveredFromMistake: recoveredFromMistake,
        );
}

/// Service for traversing learning paths defined as graphs.
class PathMapEngine {
  final TrainingPathProgressServiceV2 progress;
  final LearningPathRegistryService registry;

  final Map<String, LearningPathNode> _nodes = {};
  String? _currentId;
  final Map<String, String> _branchChoices = {};
  final Set<String> _completed = {};

  /// Returns an immutable snapshot of the current graph nodes.
  List<LearningPathNode> get allNodes =>
      List<LearningPathNode>.unmodifiable(_nodes.values);

  PathMapEngine({required this.progress, LearningPathRegistryService? registry})
      : registry = registry ?? LearningPathRegistryService.instance;

  /// Loads [nodes] directly and positions the engine at the first node.
  Future<void> loadNodes(List<LearningPathNode> nodes) async {
    _nodes
      ..clear()
      ..addEntries(nodes.map((n) => MapEntry(n.id, n)));
    _branchChoices.clear();
    _completed
      ..clear()
      ..addAll([
        for (final n in nodes)
          if (n is StageNode && progress.getStageCompletion(n.id)) n.id
      ]);
    _currentId = nodes.isNotEmpty ? nodes.first.id : null;
    await _advancePastCompleted();
  }

  /// Loads [pathId] and positions the engine at the first available node.
  Future<void> loadPath(String pathId) async {
    final templates = await registry.loadAll();
    final tpl = templates.firstWhereOrNull((e) => e.id == pathId);
    _nodes.clear();
    _currentId = null;
    _branchChoices.clear();
    _completed.clear();
    if (tpl == null) return;

    await progress.loadProgress(pathId);

    for (final s in tpl.stages) {
      final node = s.type == StageType.theory
          ? TheoryStageNode(
              id: s.id,
              nextIds: s.unlocks,
              dependsOn: s.unlockAfter,
            )
          : TrainingStageNode(
              id: s.id,
              nextIds: s.unlocks,
              dependsOn: s.unlockAfter,
            );
      _nodes[node.id] = node;
      if (progress.getStageCompletion(node.id)) {
        _completed.add(node.id);
      }
    }

    for (final entry in tpl.entryStages) {
      final node = _nodes[entry.id];
      if (node == null) continue;
      if (!_isCompleted(node) && _isUnlocked(node)) {
        _currentId = node.id;
        break;
      }
    }
    await _advancePastCompleted();
  }

  /// Returns the node currently in focus.
  LearningPathNode? getCurrentNode() =>
      _currentId != null ? _nodes[_currentId!] : null;

  /// Advances through branch [label] from the current node.
  Future<void> applyChoice(String label) async {
    final node = getCurrentNode();
    if (node is! LearningBranchNode) return;
    final targetId = node.targetFor(label);
    if (targetId == null) return;
    final target = _nodes[targetId];
    if (target == null) return;
    _branchChoices[node.id] = label;
    _currentId = target.id;
    await _advancePastCompleted();
  }

  /// Marks [nodeId] as completed and moves forward if applicable.
  Future<void> markCompleted(String nodeId) async {
    await progress.markStageCompleted(nodeId, double.nan);
    _completed.add(nodeId);
    if (_currentId == nodeId) {
      await _advanceToNext();
    }
  }

  /// Returns the next node that should be presented to the user.
  LearningPathNode? getNextNode() {
    final node = getCurrentNode();
    if (node == null) return null;
    if (node is LearningBranchNode) return null;
    if (node is StageNode) {
      for (final id in node.nextIds) {
        final next = _nodes[id];
        if (next != null && _isUnlocked(next) && !_isCompleted(next)) {
          return next;
        }
      }
    } else if (node is TheoryLessonNode) {
      for (final id in node.nextIds) {
        final next = _nodes[id];
        if (next != null && _isUnlocked(next) && !_isCompleted(next)) {
          return next;
        }
      }
    } else if (node is TheoryMiniLessonNode) {
      for (final id in node.nextIds) {
        final next = _nodes[id];
        if (next != null && _isUnlocked(next) && !_isCompleted(next)) {
          return next;
        }
      }
    }
    return null;
  }

  /// Returns a serializable snapshot of the current session.
  LearningPathSessionState getState() => LearningPathSessionState(
        currentNodeId: _currentId ?? '',
        branchChoices: Map.from(_branchChoices),
        completedStageIds: Set.from(_completed),
      );

  /// Restores the engine from a previously saved [state].
  Future<void> restoreState(LearningPathSessionState state) async {
    _currentId = state.currentNodeId.isEmpty ? null : state.currentNodeId;
    _branchChoices
      ..clear()
      ..addAll(state.branchChoices);
    _completed
      ..clear()
      ..addAll(state.completedStageIds);
    for (final id in state.completedStageIds) {
      await progress.markStageCompleted(id, double.nan);
    }
    await _advancePastCompleted();
  }

  bool _isCompleted(LearningPathNode node) {
    if (node is StageNode ||
        node is TheoryLessonNode ||
        node is TheoryMiniLessonNode) {
      return _completed.contains(node.id);
    }
    return false;
  }

  bool _isUnlocked(LearningPathNode node) {
    if (node is StageNode) {
      if (!progress.isStageUnlocked(node.id)) return false;
      return node.dependsOn.every((id) => progress.getStageCompletion(id));
    }
    return true;
  }

  Future<void> _advancePastCompleted() async {
    while (true) {
      final node = getCurrentNode();
      if (node is! StageNode &&
          node is! TheoryLessonNode &&
          node is! TheoryMiniLessonNode) break;
      if (!_isCompleted(node)) break;
      await _advanceToNext();
      if (_currentId == null) break;
    }
  }

  Future<void> _advanceToNext() async {
    final current = getCurrentNode();
    if (current is StageNode) {
      for (final id in current.nextIds) {
        final next = _nodes[id];
        if (next != null && _isUnlocked(next)) {
          _currentId = id;
          return;
        }
      }
    } else if (current is TheoryLessonNode) {
      for (final id in current.nextIds) {
        final next = _nodes[id];
        if (next != null && _isUnlocked(next)) {
          _currentId = id;
          return;
        }
      }
    } else if (current is TheoryMiniLessonNode) {
      for (final id in current.nextIds) {
        final next = _nodes[id];
        if (next != null && _isUnlocked(next)) {
          _currentId = id;
          return;
        }
      }
    }
    _currentId = null;
  }
}
