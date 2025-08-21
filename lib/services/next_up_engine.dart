import 'package:collection/collection.dart';

import '../models/v3/lesson_track.dart';
import '../models/v3/lesson_step_ref.dart';
import '../models/v3/track_meta.dart';
import 'learning_path_unlock_engine.dart';
import 'track_mastery_service.dart';
import 'lesson_progress_tracker_service.dart';
import 'lesson_track_meta_service.dart';
import 'learning_track_engine.dart';
import 'yaml_lesson_track_loader.dart';

class NextUpEngine {
  final LearningPathUnlockEngine unlockEngine;
  final TrackMasteryService masteryService;
  final LessonProgressTrackerService progressService;
  final LessonTrackMetaService metaService;
  final LearningTrackEngine trackEngine;
  final YamlLessonTrackLoader yamlLoader;

  NextUpEngine({
    LearningPathUnlockEngine? unlockEngine,
    required this.masteryService,
    LessonProgressTrackerService? progressService,
    LessonTrackMetaService? metaService,
    LearningTrackEngine trackEngine = const LearningTrackEngine(),
    YamlLessonTrackLoader? yamlLoader,
  })  : unlockEngine = unlockEngine ?? LearningPathUnlockEngine.instance,
        progressService =
            progressService ?? LessonProgressTrackerService.instance,
        metaService = metaService ?? LessonTrackMetaService.instance,
        trackEngine = trackEngine,
        yamlLoader = yamlLoader ?? YamlLessonTrackLoader.instance;

  Future<List<LessonTrack>> _loadTracks() async {
    final builtIn = trackEngine.getTracks();
    final yaml = await yamlLoader.loadTracksFromAssets();
    return [...builtIn, ...yaml];
  }

  DateTime _lastActivity(TrackMeta? meta) {
    return meta?.completedAt ??
        meta?.startedAt ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<LessonStepRef?> getNextRecommendedStep() async {
    final available = await unlockEngine.getUnlockableTracks();
    if (available.isEmpty) return null;

    final allTracks = await _loadTracks();
    final progress = await progressService.getCompletedStepsFlat();
    final mastery = await masteryService.computeTrackMastery();

    final entries = <_TrackEntry>[];
    for (final t in available) {
      final track = allTracks.firstWhere((e) => e.id == t.id, orElse: () => t);
      final ids = track.stepIds;
      if (ids.every((id) => progress[id] == true)) {
        continue; // skip completed tracks
      }
      final meta = await metaService.load(track.id);
      entries.add(
        _TrackEntry(
          track: track,
          mastery: mastery[track.id] ?? 0.0,
          lastActivity: _lastActivity(meta),
        ),
      );
    }

    if (entries.isEmpty) return null;

    entries.sort((a, b) {
      var cmp = a.mastery.compareTo(b.mastery);
      if (cmp != 0) return cmp;
      cmp = b.lastActivity.compareTo(a.lastActivity);
      if (cmp != 0) return cmp;
      return a.track.id.compareTo(b.track.id);
    });

    final best = entries.first;
    final stepId = best.track.stepIds.firstWhere(
      (id) => progress[id] != true,
      orElse: () => best.track.stepIds.last,
    );
    return LessonStepRef(trackId: best.track.id, stepId: stepId);
  }

  Future<LessonTrack?> getNextTrackRecommendation() async {
    final step = await getNextRecommendedStep();
    if (step == null) return null;
    final tracks = await _loadTracks();
    return tracks.firstWhereOrNull((t) => t.id == step.trackId);
  }
}

class _TrackEntry {
  final LessonTrack track;
  final double mastery;
  final DateTime lastActivity;

  _TrackEntry({
    required this.track,
    required this.mastery,
    required this.lastActivity,
  });
}
