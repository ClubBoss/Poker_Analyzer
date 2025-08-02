import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/skill_tree_node_celebration_overlay.dart';
import 'skill_tree_node_progress_tracker.dart';

/// Handles showing a celebration overlay when a skill tree node is completed.
class SkillTreeNodeCelebrationService {
  final SkillTreeNodeProgressTracker progress;
  final void Function(BuildContext context)? showOverlay;

  SkillTreeNodeCelebrationService({
    SkillTreeNodeProgressTracker? progress,
    this.showOverlay,
  }) : progress = progress ?? SkillTreeNodeProgressTracker.instance;

  static const _prefsPrefix = 'skill_node_celebrated_';

  /// Checks completion of [nodeId] and displays celebration once.
  Future<void> maybeCelebrate(BuildContext context, String nodeId) async {
    if (!await progress.isCompleted(nodeId)) return;

    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefsPrefix$nodeId';
    if (prefs.getBool(key) ?? false) return;
    await prefs.setBool(key, true);
    final fn = showOverlay ?? showSkillTreeNodeCelebrationOverlay;
    fn(context);
  }
}
