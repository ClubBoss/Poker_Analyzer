import 'package:flutter/foundation.dart';
import '../models/learning_branch_node.dart';
import '../models/learning_path_node.dart';
import '../models/theory_lesson_node.dart';
import '../models/theory_mini_lesson_node.dart';
import '../models/stage_type.dart';
import 'mini_lesson_library_service.dart';
import 'learning_path_stage_library.dart';
import 'learning_path_node_history.dart';
import 'path_map_engine.dart';

/// Automatically injects nodes referenced by `nextIds` when theory mini lessons
/// are completed.
class LearningPathAutoExpander {
  final MiniLessonLibraryService library;
  final LearningPathStageLibrary stageLibrary;

  const LearningPathAutoExpander({
    MiniLessonLibraryService? library,
    LearningPathStageLibrary? stageLibrary,
  })  : library = library ?? MiniLessonLibraryService.instance,
        stageLibrary = stageLibrary ?? LearningPathStageLibrary.instance;

  /// Ensures that all nodes referenced by [from.nextIds] exist in [engine].
  /// Missing nodes are loaded from libraries and appended to the path.
  Future<void> expand(PathMapEngine engine, TheoryMiniLessonNode from) async {
    await library.loadAll();
    final existing = {for (final n in engine.allNodes) n.id};
    final toAdd = <LearningPathNode>[];
    final injected = <String>{};

    void addNode(String id) {
      if (existing.contains(id) || !injected.add(id)) return;
      final mini = library.getById(id);
      if (mini != null) {
        toAdd.add(
          TheoryMiniLessonNode(
            id: mini.id,
            refId: mini.refId,
            title: mini.title,
            content: mini.content,
            tags: List<String>.from(mini.tags),
            nextIds: List<String>.from(mini.nextIds),
          ),
        );
        for (final next in mini.nextIds) {
          addNode(next);
        }
        return;
      }
      final stage = stageLibrary.getById(id);
      if (stage != null) {
        final nextIds = List<String>.from(stage.unlocks);
        final node = stage.type == StageType.theory
            ? TheoryStageNode(
                id: stage.id,
                nextIds: nextIds,
                dependsOn: List<String>.from(stage.unlockAfter),
              )
            : TrainingStageNode(
                id: stage.id,
                nextIds: nextIds,
                dependsOn: List<String>.from(stage.unlockAfter),
              );
        toAdd.add(node);
        for (final next in nextIds) {
          addNode(next);
        }
      }
    }

    for (final id in from.nextIds) {
      addNode(id);
    }
    if (toAdd.isEmpty) return;

    final updated = <LearningPathNode>[];
    for (final n in engine.allNodes) {
      updated.add(_clone(n));
    }
    updated.addAll(toAdd);

    final state = engine.getState();
    await engine.loadNodes(updated);
    await engine.restoreState(state);
    for (final id in injected) {
      await LearningPathNodeHistory.instance.markAutoInjected(id);
    }
    debugPrint('LearningPathAutoExpander: injected ${injected.join(', ')}');
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
    } else if (node is TheoryMiniLessonNode) {
      return TheoryMiniLessonNode(
        id: node.id,
        refId: node.refId,
        title: node.title,
        content: node.content,
        tags: List<String>.from(node.tags),
        nextIds: List<String>.from(node.nextIds),
        recoveredFromMistake: node.recoveredFromMistake,
      );
    }
    return node;
  }
}
