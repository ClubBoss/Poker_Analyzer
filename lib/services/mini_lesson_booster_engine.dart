import '../models/learning_branch_node.dart';
import '../models/learning_path_node.dart';
import '../models/theory_lesson_node.dart';
import '../models/theory_mini_lesson_node.dart';
import 'learning_graph_engine.dart';
import 'mini_lesson_library_service.dart';
import 'path_map_engine.dart';

/// Injects mini lesson nodes into the active learning path graph.
class MiniLessonBoosterEngine {
  final LearningPathEngine _engine;
  final MiniLessonLibraryService _library;

  const MiniLessonBoosterEngine({
    LearningPathEngine? engine,
    MiniLessonLibraryService? library,
  }) : _engine = engine ?? LearningPathEngine.instance,
       _library = library ?? MiniLessonLibraryService.instance;

  /// Inserts up to [max] mini lessons tagged by [tagList] before [targetNodeId].
  Future<void> injectBefore(
    String targetNodeId,
    List<String> tagList, {
    int max = 2,
  }) async {
    final mapEngine = _engine.engine;
    if (mapEngine == null || tagList.isEmpty || max <= 0) return;
    await _library.loadAll();
    final lessons = _library.findByTags(tagList);
    if (lessons.isEmpty) return;

    final nodes = mapEngine.allNodes;
    final byId = {for (final n in nodes) n.id: n};
    if (!byId.containsKey(targetNodeId)) return;

    final inject = <TheoryMiniLessonNode>[];
    for (final l in lessons) {
      if (inject.length >= max) break;
      final id = l.id;
      if (byId.containsKey(id)) continue; // avoid duplicates
      inject.add(
        TheoryMiniLessonNode(
          id: id,
          refId: l.refId,
          title: l.title,
          content: l.content,
          tags: l.tags,
          nextIds: const [],
          recoveredFromMistake: l.recoveredFromMistake,
        ),
      );
      byId[id] = inject.last;
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
              ? TheoryStageNode(id: n.id, nextIds: next, dependsOn: n.dependsOn)
              : TrainingStageNode(
                  id: n.id,
                  nextIds: next,
                  dependsOn: n.dependsOn,
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
          );
        }
      } else if (n is TheoryMiniLessonNode) {
        final next = List<String>.from(n.nextIds);
        var changed = false;
        for (var j = 0; j < next.length; j++) {
          if (next[j] == targetNodeId) {
            next[j] = firstId;
            changed = true;
          }
        }
        if (changed) {
          updated[i] = TheoryMiniLessonNode(
            id: n.id,
            refId: n.refId,
            title: n.title,
            content: n.content,
            tags: List<String>.from(n.tags),
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
          );
        }
      }
    }

    for (var i = 0; i < inject.length; i++) {
      final next = (i < inject.length - 1) ? inject[i + 1].id : targetNodeId;
      inject[i] = TheoryMiniLessonNode(
        id: inject[i].id,
        refId: inject[i].refId,
        title: inject[i].title,
        content: inject[i].content,
        tags: inject[i].tags,
        nextIds: [next],
        recoveredFromMistake: inject[i].recoveredFromMistake,
      );
      updated.add(inject[i]);
    }

    final state = mapEngine.getState();
    await mapEngine.loadNodes(updated);
    await mapEngine.restoreState(state);
  }

  LearningPathNode _clone(LearningPathNode node) {
    if (node is LearningBranchNode) {
      return LearningBranchNode(
        id: node.id,
        prompt: node.prompt,
        branches: Map<String, String>.from(node.branches),
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
