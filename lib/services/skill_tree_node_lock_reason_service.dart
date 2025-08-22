import '../models/skill_tree_node_model.dart';
import 'skill_tree_library_service.dart';
import 'skill_tree_node_progress_tracker.dart';
import 'skill_tree_stage_gate_evaluator.dart';
import 'skill_tree_unlock_evaluator.dart';

/// Provides explanations for why a skill tree node is locked.
class SkillTreeNodeLockReasonService {
  final SkillTreeLibraryService _library;
  final SkillTreeNodeProgressTracker _progress;
  final SkillTreeStageGateEvaluator _stageEval;
  final SkillTreeUnlockEvaluator _unlockEval;

  SkillTreeNodeLockReasonService({
    SkillTreeLibraryService? library,
    SkillTreeNodeProgressTracker? progress,
    SkillTreeStageGateEvaluator? stageEvaluator,
    SkillTreeUnlockEvaluator? unlockEvaluator,
  }) : _library = library ?? SkillTreeLibraryService.instance,
       _progress = progress ?? SkillTreeNodeProgressTracker.instance,
       _stageEval = stageEvaluator ?? const SkillTreeStageGateEvaluator(),
       _unlockEval =
           unlockEvaluator ??
           SkillTreeUnlockEvaluator(
             progress: progress ?? SkillTreeNodeProgressTracker.instance,
           );

  Future<String?> getLockReason(SkillTreeNodeModel node) async {
    final res = _library.getTree(node.category);
    final tree = res?.tree;
    if (tree == null) return null;

    await _progress.isCompleted('');
    final completed = _progress.completedNodeIds.value;

    final unlockedIds = _unlockEval
        .getUnlockedNodes(tree)
        .map((n) => n.id)
        .toSet();
    if (unlockedIds.contains(node.id)) return null;

    if (!_stageEval.isStageUnlocked(tree, node.level, completed)) {
      final blockers = _stageEval.getBlockingNodes(tree, node.level, completed);
      if (blockers.isNotEmpty) {
        blockers.sort((a, b) => b.level.compareTo(a.level));
        final b = blockers.first;
        return 'Завершите этап ${b.level}: ${b.title}';
      }
      return 'Завершите предыдущие этапы';
    }

    for (final id in node.prerequisites) {
      if (!completed.contains(id)) {
        final b = tree.nodes[id];
        final title = b?.title ?? id;
        return 'Завершите узел: $title';
      }
    }
    return null;
  }
}
