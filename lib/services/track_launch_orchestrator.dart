import 'package:flutter/material.dart';

import '../main.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/game_type.dart';
import '../core/training/engine/training_type_engine.dart';
import '../models/training_track.dart';
import 'adaptive_learning_flow_engine.dart';
import 'training_session_launcher.dart';
import 'track_play_recorder.dart';

/// Launches the highest priority training item from an [AdaptiveLearningPlan].
class TrackLaunchOrchestrator {
  final TrainingSessionLauncher launcher;
  final TrackPlayRecorder recorder;

  TrackLaunchOrchestrator({
    this.launcher = const TrainingSessionLauncher(),
    TrackPlayRecorder? recorder,
  }) : recorder = recorder ?? TrackPlayRecorder.instance;

  /// Launches the next recommended track or mistake replay pack.
  Future<void> launchNextTrack(AdaptiveLearningPlan plan) async {
    TrainingPackTemplateV2? pack;
    String goalId = '';

    if (plan.mistakeReplayPack != null) {
      pack = plan.mistakeReplayPack;
      goalId = 'mistake_replay';
    } else if (plan.recommendedTracks.isNotEmpty) {
      final TrainingTrack track = plan.recommendedTracks.first;
      pack = TrainingPackTemplateV2(
        id: track.id,
        name: track.title,
        trainingType: TrainingType.pushFold,
        tags: List<String>.from(track.tags),
        spots: track.spots,
        spotCount: track.spots.length,
        created: DateTime.now(),
        gameType: GameType.tournament,
        positions: const [],
        meta: const {'origin': 'learning_track'},
      );
      goalId = track.goalId;
    }

    if (pack != null) {
      await recorder.recordStart(goalId);
      await launcher.launch(pack);
    } else {
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        await showDialog<void>(
          context: ctx,
          builder: (_) =>
              AlertDialog(content: Text('\u{1F389} All caught up!')),
        );
      }
    }
  }
}
