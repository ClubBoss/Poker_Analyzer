import 'package:flutter/material.dart';
import 'package:poker_analyzer/widgets/dark_alert_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import 'skill_tree_node_progress_tracker.dart';
import 'track_recommendation_engine.dart';
import 'skill_tree_navigator.dart';

/// Shows a celebratory dialog when a track is completed for the first time.
class TrackCompletionCelebrationService {
  final SkillTreeNodeProgressTracker progress;

  TrackCompletionCelebrationService({SkillTreeNodeProgressTracker? progress})
    : progress = progress ?? SkillTreeNodeProgressTracker.instance;

  static TrackCompletionCelebrationService instance =
      TrackCompletionCelebrationService();

  static const _prefsPrefix = 'track_completion_shown_';

  /// Shows a celebration modal if [trackId] has been completed and not yet
  /// celebrated.
  Future<void> maybeCelebrate(String trackId) async {
    if (!await progress.isTrackCompleted(trackId)) return;

    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefsPrefix$trackId';
    if (prefs.getBool(key) ?? false) return;
    await prefs.setBool(key, true);

    final ctx = navigatorKey.currentState?.context;
    if (ctx == null || !ctx.mounted) return;

    final nextTrackId = TrackRecommendationEngine.getNextTrack(trackId);

    await showDialog<void>(
      context: ctx,
      builder: (context) => DarkAlertDialog(
        title: const Text('🎉 Трек завершён!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.2),
              duration: const Duration(milliseconds: 700),
              builder: (context, value, child) =>
                  Transform.scale(scale: value, child: child),
              child: const Icon(
                Icons.celebration,
                size: 48,
                color: Colors.orange,
              ),
            ),
            SizedBox(height: 12),
            Text('Вы прошли весь трек!'),
          ],
        ),
        actions: [
          if (nextTrackId != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                SkillTreeNavigator.instance.openTrack(nextTrackId);
              },
              child: const Text('Открыть следующий трек'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Продолжить'),
          ),
        ],
      ),
    );
  }
}
