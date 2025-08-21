import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/skill_tree.dart';
import 'skill_tree_unlock_evaluator.dart';
import 'skill_tree_stage_gate_evaluator.dart';
import 'skill_tree_node_progress_tracker.dart';

/// Shows a toast when new skill tree nodes or stages become unlocked.
class SkillTreeUnlockNotificationService {
  final SkillTreeNodeProgressTracker progress;

  SkillTreeUnlockNotificationService({SkillTreeNodeProgressTracker? progress})
      : progress = progress ?? SkillTreeNodeProgressTracker.instance;

  static String _nodeKey(String id) => 'skill_tree_unlocked_nodes_$id';
  static String _stageKey(String id) => 'skill_tree_unlocked_stages_$id';

  /// Checks [tree] for newly unlocked nodes or stages and shows notifications.
  Future<void> maybeNotify(BuildContext context, SkillTree tree) async {
    final trackId =
        tree.nodes.values.isNotEmpty ? tree.nodes.values.first.category : '';
    if (trackId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();

    await progress.isCompleted('');
    final completed = progress.completedNodeIds.value;

    final evaluator = SkillTreeUnlockEvaluator(progress: progress);
    final unlockedNodes =
        evaluator.getUnlockedNodes(tree).map((n) => n.id).toSet();
    final prevNodes =
        prefs.getStringList(_nodeKey(trackId))?.toSet() ?? <String>{};
    final newNodes = unlockedNodes.difference(prevNodes);

    const gateEval = SkillTreeStageGateEvaluator();
    final unlockedStages = gateEval.getUnlockedStages(tree, completed).toSet();
    final prevStages =
        prefs.getStringList(_stageKey(trackId))?.map(int.parse).toSet() ??
            <int>{};
    final newStages = unlockedStages.difference(prevStages);

    for (final level in newStages) {
      if (!context.mounted) break;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Открыт новый этап: $level')));
    }

    for (final id in newNodes) {
      if (!context.mounted) break;
      final title = tree.nodes[id]?.title ?? id;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Открыт новый узел: $title')));
    }

    await prefs.setStringList(_nodeKey(trackId), unlockedNodes.toList());
    await prefs.setStringList(
      _stageKey(trackId),
      unlockedStages.map((e) => e.toString()).toList(),
    );
  }
}
