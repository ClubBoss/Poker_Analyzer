import '../models/skill_tree_dependency_link.dart';
import 'skill_tree_graph_service.dart';
import 'skill_tree_library_service.dart';
import 'skill_tree_node_detail_unlock_hint_service.dart';
import 'skill_tree_node_progress_tracker.dart';
import 'skill_tree_track_resolver.dart';
import 'skill_tree_unlock_evaluator.dart';

/// Computes dependency chains and explanations for locked skill tree nodes.
class SkillTreeDependencyLinkService {
  final SkillTreeLibraryService _library;
  final SkillTreeGraphService _graph;
  final SkillTreeNodeDetailUnlockHintService _hintService;
  final SkillTreeNodeProgressTracker _progress;
  final SkillTreeTrackResolver _resolver;

  SkillTreeDependencyLinkService({
    SkillTreeLibraryService? library,
    SkillTreeGraphService? graph,
    SkillTreeNodeDetailUnlockHintService? hintService,
    SkillTreeNodeProgressTracker? progress,
    SkillTreeTrackResolver? resolver,
  }) : _library = library ?? SkillTreeLibraryService.instance,
       _graph = graph ?? const SkillTreeGraphService(),
       _hintService =
           hintService ?? const SkillTreeNodeDetailUnlockHintService(),
       _progress = progress ?? SkillTreeNodeProgressTracker.instance,
       _resolver = resolver ?? SkillTreeTrackResolver.instance;

  /// Returns locked dependency links for [nodeId].
  Future<List<SkillTreeDependencyLink>> getDependencies(String nodeId) async {
    final trackId = await _resolver.getTrackIdForNode(nodeId);
    if (trackId == null) return const [];
    final res = _library.getTrack(trackId);
    final tree = res?.tree;
    if (tree == null) return const [];

    await _progress.isCompleted('');
    final completed = _progress.completedNodeIds.value;

    final unlockedEval = SkillTreeUnlockEvaluator(progress: _progress);
    final unlocked = unlockedEval
        .getUnlockedNodes(tree)
        .map((n) => n.id)
        .toSet();

    final result = <SkillTreeDependencyLink>[];
    final visited = <String>{};

    void visit(String id) {
      if (!visited.add(id)) return;
      final node = tree.nodes[id];
      if (node == null) return;
      final isCompleted = completed.contains(id);
      final isUnlocked = unlocked.contains(id);
      if (!isCompleted && !isUnlocked) {
        final prereqs = _graph.getPrerequisiteChain(tree, id);
        final hint =
            _hintService.getUnlockHint(
              node: node,
              unlocked: unlocked,
              completed: completed,
              track: tree,
            ) ??
            '';
        result.add(
          SkillTreeDependencyLink(
            nodeId: id,
            prerequisites: prereqs,
            hint: hint,
          ),
        );
      }
      for (final p in node.prerequisites) {
        visit(p);
      }
    }

    visit(nodeId);
    return result;
  }
}
