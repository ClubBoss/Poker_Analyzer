import 'package:flutter/material.dart';
import 'package:poker_analyzer/widgets/dark_alert_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import 'skill_tree_library_service.dart';
import 'skill_tree_node_progress_tracker.dart';
import 'skill_tree_stage_completion_evaluator.dart';
import 'skill_tree_milestone_analytics_logger.dart';
import 'track_completion_celebration_service.dart';
import 'track_completion_reward_service.dart';
import 'track_reward_unlocker_service.dart';
import 'track_milestone_unlocker_service.dart';
import '../widgets/track_completion_dialog.dart';

/// Shows a celebratory dialog when a skill tree stage is fully completed.
class StageCompletionCelebrationService {
  final SkillTreeLibraryService library;
  final SkillTreeNodeProgressTracker progress;
  final SkillTreeStageCompletionEvaluator evaluator;

  StageCompletionCelebrationService({
    SkillTreeLibraryService? library,
    SkillTreeNodeProgressTracker? progress,
    SkillTreeStageCompletionEvaluator? evaluator,
  }) : library = library ?? SkillTreeLibraryService.instance,
       progress = progress ?? SkillTreeNodeProgressTracker.instance,
       evaluator = evaluator ?? const SkillTreeStageCompletionEvaluator();

  static StageCompletionCelebrationService instance =
      StageCompletionCelebrationService();

  Future<void> _ensureLoaded() async {
    if (library.getAllNodes().isEmpty) {
      await library.reload();
    }
    await progress.isCompleted('');
  }

  /// Checks the highest completed stage in [trackId] and shows a dialog once.
  Future<void> checkAndCelebrate(String trackId) async {
    await _ensureLoaded();
    final tree = library.getTrack(trackId)?.tree;
    if (tree == null) return;
    final completed = progress.completedNodeIds.value;
    final completedStages = evaluator.getCompletedStages(tree, completed);
    if (completedStages.isEmpty) return;
    final stageIndex = completedStages.last;
    final totalStages = tree.nodes.values.map((n) => n.level).toSet().length;

    final prefs = await SharedPreferences.getInstance();
    final key = 'stage_celebrated_${trackId}_$stageIndex';
    if (prefs.getBool(key) ?? false) return;
    await prefs.setBool(key, true);

    final ctx = navigatorKey.currentState?.context;
    if (ctx == null || !ctx.mounted) return;

    await showDialog<void>(
      context: ctx,
      builder: (context) => DarkAlertDialog(
        title: const Text('Этап завершён'),
        content: Text('Этап $stageIndex успешно завершён!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    await SkillTreeMilestoneAnalyticsLogger.instance.logStageCompleted(
      trackId: trackId,
      stageIndex: stageIndex,
      totalStages: totalStages,
    );

    await TrackMilestoneUnlockerService.instance.unlockNextStage(trackId);
  }

  /// Celebrates full track completion for [trackId] once.
  Future<void> checkAndCelebrateTrackCompletion(String trackId) async {
    await _ensureLoaded();
    final tree = library.getTrack(trackId)?.tree;
    if (tree == null) return;
    final completed = progress.completedNodeIds.value;
    final completedStages = evaluator.getCompletedStages(tree, completed);
    final totalStages = tree.nodes.values.map((n) => n.level).toSet().length;
    if (completedStages.length < totalStages) return;
    if (await progress.isTrackCompleted(trackId)) return;
    await progress.markTrackCompleted(trackId);

    await TrackCompletionCelebrationService.instance.maybeCelebrate(trackId);

    final granted = await TrackCompletionRewardService.instance.grantReward(
      trackId,
    );
    if (granted) {
      await TrackRewardUnlockerService.instance.unlockReward(trackId);
    }

    final ctx = navigatorKey.currentState?.context;
    if (ctx != null && ctx.mounted) {
      await TrackCompletionDialog.show(ctx, trackId);
    }

    await SkillTreeMilestoneAnalyticsLogger.instance.logTrackCompleted(
      trackId: trackId,
    );
  }
}
