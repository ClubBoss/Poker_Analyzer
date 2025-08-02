import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'skill_tree_track_completion_evaluator.dart';
import 'skill_tree_track_progress_service.dart';
import '../widgets/track_celebration_dialog.dart';
import '../screens/skill_tree_track_launcher.dart';

/// Detects when a skill tree track is completed for the first time and
/// shows a celebration dialog with an option to open the next track.
class TrackCompletionCelebrationService {
  final SkillTreeTrackCompletionEvaluator evaluator;
  final SkillTreeTrackProgressService progress;

  TrackCompletionCelebrationService({
    SkillTreeTrackCompletionEvaluator? evaluator,
    SkillTreeTrackProgressService? progress,
  })  : evaluator = evaluator ?? SkillTreeTrackCompletionEvaluator(),
        progress = progress ?? SkillTreeTrackProgressService();

  static final instance = TrackCompletionCelebrationService();

  static const _prefsKey = 'celebrated_track_ids';

  /// Checks completion of [trackId] and displays celebration once.
  Future<void> maybeCelebrate(BuildContext context, String trackId) async {
    if (!await evaluator.isCompleted(trackId)) return;

    final prefs = await SharedPreferences.getInstance();
    final celebrated = prefs.getStringList(_prefsKey) ?? <String>[];
    if (celebrated.contains(trackId)) return;

    celebrated.add(trackId);
    await prefs.setStringList(_prefsKey, celebrated);

    final next = await progress.getNextTrack();
    final nextId = next?.tree.nodes.values.isNotEmpty == true
        ? next!.tree.nodes.values.first.category
        : null;

    await showTrackCelebrationDialog(
      context,
      trackId,
      onNext: nextId == null
          ? null
          : () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => SkillTreeTrackLauncher(trackId: nextId),
                ),
              );
            },
    );
  }
}
