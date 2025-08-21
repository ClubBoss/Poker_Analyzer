import 'package:flutter/material.dart';
import 'package:poker_analyzer/widgets/dark_alert_dialog.dart';

import '../main.dart';
import '../screens/player_stats_screen.dart';
import 'skill_tree_library_service.dart';
import 'skill_tree_node_progress_tracker.dart';

/// Grants a one-time reward when a track is completed for the first time.
class TrackRewardUnlockerService {
  final SkillTreeNodeProgressTracker progress;
  final SkillTreeLibraryService library;

  TrackRewardUnlockerService({
    SkillTreeNodeProgressTracker? progress,
    SkillTreeLibraryService? library,
  })  : progress = progress ?? SkillTreeNodeProgressTracker.instance,
        library = library ?? SkillTreeLibraryService.instance;

  /// Singleton instance.
  static TrackRewardUnlockerService instance = TrackRewardUnlockerService();

  Future<void> _ensureLoaded() async {
    if (library.getAllTracks().isEmpty) {
      await library.reload();
    }
    await progress.isTrackCompleted('');
  }

  /// Displays a reward dialog for [trackId] if it is completed.
  Future<void> unlockReward(String trackId) async {
    await _ensureLoaded();
    if (!await progress.isTrackCompleted(trackId)) return;
    final ctx = navigatorKey.currentState?.context;
    if (ctx == null || !ctx.mounted) return;

    final title = _resolveTrackTitle(trackId);

    await showDialog<void>(
      context: ctx,
      builder: (context) => DarkAlertDialog(
        title: const Text('Награда за прохождение!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.card_giftcard, size: 48, color: Colors.orange),
            const SizedBox(height: 12),
            Text(title),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(PlayerStatsScreen.route);
            },
            child: const Text('Посмотреть награды'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _resolveTrackTitle(String trackId) {
    final track = library.getTrack(trackId)?.tree;
    if (track == null) return trackId;
    if (track.roots.isNotEmpty) return track.roots.first.title;
    if (track.nodes.isNotEmpty) return track.nodes.values.first.title;
    return trackId;
  }
}
