import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/skill_tree_track_celebration_screen.dart';
import '../screens/skill_tree_track_launcher.dart';
import 'skill_tree_track_completion_evaluator.dart';
import 'skill_tree_track_progress_service.dart';

/// Triggers a celebratory screen when a skill tree track is completed.
class SkillTreeTrackCelebrationService {
  final SkillTreeTrackCompletionEvaluator evaluator;
  final SkillTreeTrackProgressService progress;

  SkillTreeTrackCelebrationService({
    SkillTreeTrackCompletionEvaluator? evaluator,
    SkillTreeTrackProgressService? progress,
  }) : evaluator = evaluator ?? SkillTreeTrackCompletionEvaluator(),
       progress = progress ?? SkillTreeTrackProgressService();

  /// Singleton instance.
  static final instance = SkillTreeTrackCelebrationService();

  static const _prefsKey = 'skill_tree_track_celebrations';

  /// Checks completion of [trackId] and shows celebration once.
  Future<void> maybeCelebrate(BuildContext context, String trackId) async {
    if (!await evaluator.isCompleted(trackId)) return;

    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getStringList(_prefsKey) ?? <String>[];
    if (done.contains(trackId)) return;

    done.add(trackId);
    await prefs.setStringList(_prefsKey, done);

    final next = await progress.getNextTrack();
    final nextId = next?.tree.nodes.values.isNotEmpty == true
        ? next!.tree.nodes.values.first.category
        : null;

    await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => SkillTreeTrackCelebrationScreen(
          trackId: trackId,
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
        ),
      ),
    );
  }
}
