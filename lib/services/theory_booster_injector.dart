import '../models/learning_branch_node.dart';
import '../models/learning_path_node.dart';
import '../models/theory_lesson_node.dart';
import 'learning_graph_engine.dart';
import 'learning_path_graph_orchestrator.dart';
import 'path_map_engine.dart';
import 'theory_reinforcement_log_service.dart';

/// Injects review theory nodes into the active learning path graph.
class TheoryBoosterInjector {
  final LearningPathEngine _engine;
  final LearningPathGraphOrchestrator _orchestrator;

  const TheoryBoosterInjector({
    LearningPathEngine? engine,
    LearningPathGraphOrchestrator? orchestrator,
  })  : _engine = engine ?? LearningPathEngine.instance,
        _orchestrator = orchestrator ?? LearningPathGraphOrchestrator();

  static final TheoryBoosterInjector instance = TheoryBoosterInjector();

  /// Inserts [reviewNodeIds] before [targetNodeId] if possible.
  Future<void> injectBefore(
      String targetNodeId, List<String> reviewNodeIds) async {
    final mapEngine = _engine.engine;
    if (mapEngine == null || reviewNodeIds.isEmpty) return;

    final nodes = mapEngine.allNodes;
    final byId = {for (final n in nodes) n.id: n};
    if (!byId.containsKey(targetNodeId)) return;

    final source = await _orchestrator.loadGraph();
    final sourceById = {for (final n in source) n.id: n};

    final inject = <TheoryLessonNode>[];
    for (final id in reviewNodeIds) {
      if (byId.containsKey(id)) continue; // avoid duplicates
      final n = sourceById[id];
      if (n is TheoryLessonNode) {
        inject.add(TheoryLessonNode(
          id: n.id,
          refId: n.refId,
          title: n.title,
          content: n.content,
          nextIds: const [],
          recoveredFromMistake: n.recoveredFromMistake,
        ));
        byId[id] = n; // reserve id
      }
    }
    if (inject.isEmpty) return;

    final updated = <LearningPathNode>[];
    for (final n in nodes) {
      updated.add(_clone(n));
    }

    final firstId = inject.first.id;

    for (var i = 0; i < updated.length; i++) {
      final n = updated[i];
      if (n is StageNode) {
        final next = List<String>.from(n.nextIds);
        var changed = false;
        for (var j = 0; j < next.length; j++) {
          if (next[j] == targetNodeId) {
            next[j] = firstId;
            changed = true;
          }
        }
        if (changed) {
          updated[i] = n is TheoryStageNode
              ? TheoryStageNode(
                  id: n.id,
                  nextIds: next,
                  dependsOn: n.dependsOn,
                  recoveredFromMistake: n.recoveredFromMistake,
                )
              : TrainingStageNode(
                  id: n.id,
                  nextIds: next,
                  dependsOn: n.dependsOn,
                  recoveredFromMistake: n.recoveredFromMistake,
                );
        }
      } else if (n is TheoryLessonNode) {
        final next = List<String>.from(n.nextIds);
        var changed = false;
        for (var j = 0; j < next.length; j++) {
          if (next[j] == targetNodeId) {
            next[j] = firstId;
            changed = true;
          }
        }
        if (changed) {
          updated[i] = TheoryLessonNode(
            id: n.id,
            refId: n.refId,
            title: n.title,
            content: n.content,
            nextIds: next,
            recoveredFromMistake: n.recoveredFromMistake,
          );
        }
      } else if (n is LearningBranchNode) {
        final branches = Map<String, String>.from(n.branches);
        var changed = false;
        n.branches.forEach((label, target) {
          if (target == targetNodeId) {
            branches[label] = firstId;
            changed = true;
          }
        });
        if (changed) {
          updated[i] = LearningBranchNode(
            id: n.id,
            prompt: n.prompt,
            branches: branches,
            recoveredFromMistake: n.recoveredFromMistake,
          );
        }
      }
    }

    for (var i = 0; i < inject.length; i++) {
      final next = (i < inject.length - 1) ? inject[i + 1].id : targetNodeId;
      inject[i] = TheoryLessonNode(
        id: inject[i].id,
        refId: inject[i].refId,
        title: inject[i].title,
        content: inject[i].content,
        nextIds: [next],
      );
      updated.add(inject[i]);
    }

    final state = mapEngine.getState();
    await mapEngine.loadNodes(updated);
    await mapEngine.restoreState(state);
    for (final n in inject) {
      await TheoryReinforcementLogService.instance
          .logInjection(n.id, 'standard', 'auto');
    }
  }

  LearningPathNode _clone(LearningPathNode node) {
    if (node is LearningBranchNode) {
      return LearningBranchNode(
        id: node.id,
        prompt: node.prompt,
        branches: Map<String, String>.from(node.branches),
        recoveredFromMistake: node.recoveredFromMistake,
      );
    } else if (node is TrainingStageNode) {
      return TrainingStageNode(
        id: node.id,
        nextIds: List<String>.from(node.nextIds),
        dependsOn: List<String>.from(node.dependsOn),
        recoveredFromMistake: node.recoveredFromMistake,
      );
    } else if (node is TheoryStageNode) {
      return TheoryStageNode(
        id: node.id,
        nextIds: List<String>.from(node.nextIds),
        dependsOn: List<String>.from(node.dependsOn),
        recoveredFromMistake: node.recoveredFromMistake,
      );
    } else if (node is TheoryLessonNode) {
      return TheoryLessonNode(
        id: node.id,
        refId: node.refId,
        title: node.title,
        content: node.content,
        nextIds: List<String>.from(node.nextIds),
        recoveredFromMistake: node.recoveredFromMistake,
      );
    }
    return node;
  }
}
