import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'skill_tree_track_completion_evaluator.dart';
import '../screens/skill_tree_track_celebration_screen.dart';
import 'skill_tree_milestone_analytics_logger.dart';

/// Shows a celebration when a skill tree track is fully completed.
class SkillTreeTrackCompletionCelebrator {
  final SkillTreeTrackCompletionEvaluator evaluator;

  SkillTreeTrackCompletionCelebrator({
    SkillTreeTrackCompletionEvaluator? evaluator,
  }) : evaluator = evaluator ?? SkillTreeTrackCompletionEvaluator();

  static const _prefsKey = 'shown_track_celebrations';

  /// Singleton instance.
  static final instance = SkillTreeTrackCompletionCelebrator();

  /// Checks [trackId] completion and shows celebration once.
  Future<void> maybeCelebrate(BuildContext context, String trackId) async {
    if (!await evaluator.isCompleted(trackId)) return;

    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getStringList(_prefsKey) ?? <String>[];
    if (shown.contains(trackId)) return;

    shown.add(trackId);
    await prefs.setStringList(_prefsKey, shown);
    unawaited(
      SkillTreeMilestoneAnalyticsLogger.instance.logTrackCompleted(
        trackId: trackId,
      ),
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => SkillTreeTrackCelebrationScreen(trackId: trackId),
      ),
    );
  }
}
