import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/skill_tree.dart';
import 'skill_tree_final_node_completion_detector.dart';
import 'skill_tree_milestone_overlay_service.dart';
import 'skill_tree_motivational_hint_engine.dart';
import 'skill_tree_progress_analytics_service.dart';

/// Detects full skill tree completion and shows a celebration overlay.
class SkillTreeCelebrationTriggerService {
  final SkillTreeFinalNodeCompletionDetector detector;
  final SkillTreeProgressAnalyticsService analytics;
  final SkillTreeMilestoneOverlayService overlay;

  SkillTreeCelebrationTriggerService({
    SkillTreeFinalNodeCompletionDetector? detector,
    SkillTreeProgressAnalyticsService? analytics,
    SkillTreeMilestoneOverlayService? overlay,
  })  : detector = detector ?? SkillTreeFinalNodeCompletionDetector(),
        analytics = analytics ?? SkillTreeProgressAnalyticsService(),
        overlay = overlay ??
            SkillTreeMilestoneOverlayService(
              engine: _CompletionMessageEngine(),
            );

  static const _prefix = 'celebration_done_';

  /// Checks [tree] completion and shows celebration once per tree.
  Future<void> maybeCelebrate(BuildContext context, SkillTree tree) async {
    final id =
        tree.nodes.values.isNotEmpty ? tree.nodes.values.first.category : '';
    final key = '$_prefix$id';
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(key) ?? false) return;
    if (!await detector.isTreeCompleted(tree)) return;
    await prefs.setBool(key, true);
    final stats = await analytics.getStats(tree);
    await overlay.maybeShow(context, stats);
  }
}

class _CompletionMessageEngine extends SkillTreeMotivationalHintEngine {
  _CompletionMessageEngine();

  @override
  Future<String?> getMotivationalMessage(SkillTreeProgressStats stats) async {
    return "You've completed this track!";
  }
}
