import 'package:flutter/material.dart';

import '../services/skill_tree_track_progress_service.dart';
import 'skill_tree_track_intro_screen.dart';
import 'skill_tree_path_screen.dart';

/// Decides whether to show [SkillTreeTrackIntroScreen] or
/// [SkillTreePathScreen] based on whether the user has already
/// started the track.
class SkillTreeTrackLauncher extends StatelessWidget {
  final String trackId;
  const SkillTreeTrackLauncher({super.key, required this.trackId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: SkillTreeTrackProgressService().isStarted(trackId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final started = snapshot.data!;
        return started
            ? SkillTreePathScreen(trackId: trackId)
            : SkillTreeTrackIntroScreen(trackId: trackId);
      },
    );
  }
}
