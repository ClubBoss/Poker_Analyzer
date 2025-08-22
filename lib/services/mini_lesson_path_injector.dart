import '../models/learning_branch_node.dart';
import '../models/learning_path_node.dart';
import '../models/theory_lesson_node.dart';
import '../models/theory_mini_lesson_node.dart';
import 'learning_graph_engine.dart';
import 'learning_path_stage_library.dart';
import 'mini_lesson_library_service.dart';
import 'path_map_engine.dart';

/// Injects mini theory lessons into the active learning path graph
/// based on tag overlap.
class MiniLessonPathInjector {
  final LearningPathEngine engine;
  final MiniLessonLibraryService library;
  final LearningPathStageLibrary stageLibrary;

  MiniLessonPathInjector({
    LearningPathEngine? engine,
    MiniLessonLibraryService? library,
    LearningPathStageLibrary? stageLibrary,
  }) : engine = engine ?? LearningPathEngine.instance,
       library = library ?? MiniLessonLibraryService.instance,
       stageLibrary = stageLibrary ?? LearningPathStageLibrary.instance;

  static final MiniLessonPathInjector instance = MiniLessonPathInjector();

  /// Inserts [lessons] after nodes reachable from [branch] when their
  /// tags overlap. Duplicate lesson ids are ignored.
  Future<void> inject(
    LearningBranchNode branch,
    List<TheoryMiniLessonNode> lessons,
  ) async {
    final mapEngine = engine.engine;
    if (mapEngine == null || lessons.isEmpty) return;
    final nodes = mapEngine.allNodes;
    final byId = {for (final n in nodes) n.id: n};
    if (!byId.containsKey(branch.id)) return;

    final existing = {for (final n in nodes) n.id};
    final filtered = [
      for (final l in lessons)
        if (!existing.contains(l.id)) l,
    ];
    if (filtered.isEmpty) return;

    var updated = [for (final n in nodes) _clone(n)];

    for (final targetId in branch.branches.values) {
      final target = byId[targetId];
      if (target == null) continue;
      final tags = _tagsForNode(target);
      if (tags.isEmpty) continue;
      final matched = filtered
          .where((m) => m.tags.any((t) => tags.contains(t)))
          .toList();
      if (matched.isNotEmpty) {
        updated = _injectAfter(updated, targetId, matched);
      }
    }

    final state = mapEngine.getState();
    await mapEngine.loadNodes(updated);
    await mapEngine.restoreState(state);
  }

  List<String> _tagsForNode(LearningPathNode node) {
    if (node is TheoryMiniLessonNode) {
      return [for (final t in node.tags) t.trim().toLowerCase()];
    } else if (node is StageNode) {
      final stage = stageLibrary.getById(node.id);
      if (stage != null) {
        return [for (final t in stage.tags) t.trim().toLowerCase()];
      }
    }
    return const [];
  }

  List<LearningPathNode> _injectAfter(
    List<LearningPathNode> nodes,
    String targetId,
    List<TheoryMiniLessonNode> lessons,
  ) {
    final index = nodes.indexWhere((n) => n.id == targetId);
    if (index < 0 || lessons.isEmpty) return nodes;
    final target = nodes[index];

    final next = _getNextIds(target);
    nodes[index] = _withNextIds(target, [lessons.first.id]);

    for (var i = 0; i < lessons.length; i++) {
      final n = lessons[i];
      final nextIds = i < lessons.length - 1 ? [lessons[i + 1].id] : next;
      nodes.add(
        TheoryMiniLessonNode(
          id: n.id,
          refId: n.refId,
          title: n.title,
          content: n.content,
          tags: List<String>.from(n.tags),
          nextIds: nextIds,
        ),
      );
    }
    return nodes;
  }

  List<String> _getNextIds(LearningPathNode node) {
    if (node is StageNode) return node.nextIds;
    if (node is TheoryLessonNode) return node.nextIds;
    if (node is TheoryMiniLessonNode) return node.nextIds;
    return const [];
  }

  LearningPathNode _withNextIds(LearningPathNode node, List<String> next) {
    if (node is TrainingStageNode) {
      return TrainingStageNode(
        id: node.id,
        nextIds: next,
        dependsOn: List<String>.from(node.dependsOn),
        recoveredFromMistake: node.recoveredFromMistake,
      );
    } else if (node is TheoryStageNode) {
      return TheoryStageNode(
        id: node.id,
        nextIds: next,
        dependsOn: List<String>.from(node.dependsOn),
        recoveredFromMistake: node.recoveredFromMistake,
      );
    } else if (node is TheoryLessonNode) {
      return TheoryLessonNode(
        id: node.id,
        refId: node.refId,
        title: node.title,
        content: node.content,
        nextIds: next,
        recoveredFromMistake: node.recoveredFromMistake,
      );
    } else if (node is TheoryMiniLessonNode) {
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

  LearningPathNode _clone(LearningPathNode node) {
    return _withNextIds(node, _getNextIds(node));
  }
}
