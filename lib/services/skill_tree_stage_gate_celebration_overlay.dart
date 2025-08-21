import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/skill_tree.dart';
import 'skill_tree_stage_gate_evaluator.dart';
import 'skill_tree_node_progress_tracker.dart';
import '../widgets/skill_tree_stage_gate_celebration_overlay.dart';
import 'skill_tree_milestone_analytics_logger.dart';

/// Shows a brief overlay when a new skill tree stage becomes unlocked.
class SkillTreeStageGateCelebrationOverlay {
  final SkillTreeNodeProgressTracker progress;

  SkillTreeStageGateCelebrationOverlay({SkillTreeNodeProgressTracker? progress})
      : progress = progress ?? SkillTreeNodeProgressTracker.instance;

  static String _prefsKey(String id) => 'skill_tree_stage_celebrations_$id';

  /// Checks [tree] for newly unlocked stages and celebrates each once.
  Future<void> maybeCelebrate(BuildContext context, SkillTree tree) async {
    final trackId =
        tree.nodes.values.isNotEmpty ? tree.nodes.values.first.category : '';
    if (trackId.isEmpty) return;

    await progress.isCompleted('');
    final completed = progress.completedNodeIds.value;

    const gateEval = SkillTreeStageGateEvaluator();
    final unlockedStages = gateEval.getUnlockedStages(tree, completed).toSet();

    final prefs = await SharedPreferences.getInstance();
    final prev =
        prefs.getStringList(_prefsKey(trackId))?.map(int.parse).toSet() ??
            <int>{};

    final newStages = unlockedStages.difference(prev).toList()..sort();

    for (final level in newStages) {
      if (!context.mounted) break;
      final title = _firstTitleForStage(tree, level);
      final msg = '🎯 Открыт этап $level${title != null ? ': $title' : ''}!';
      showSkillTreeStageGateCelebrationOverlay(context, msg);
      unawaited(
        SkillTreeMilestoneAnalyticsLogger.instance.logStageUnlocked(
          trackId: trackId,
          stage: level,
        ),
      );
      await Future.delayed(const Duration(seconds: 2));
    }

    await prefs.setStringList(
      _prefsKey(trackId),
      unlockedStages.map((e) => e.toString()).toList(),
    );
  }

  String? _firstTitleForStage(SkillTree tree, int level) {
    for (final node in tree.nodes.values) {
      if (node.level == level) return node.title;
    }
    return null;
  }
}
