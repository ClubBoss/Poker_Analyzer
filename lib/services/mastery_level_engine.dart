import '../models/mastery_level.dart';
import 'lesson_progress_tracker_service.dart';
import 'lesson_track_meta_service.dart';
import 'learning_track_engine.dart';

class MasteryLevelEngine {
  final LessonProgressTrackerService _progress;
  final LessonTrackMetaService _trackMeta;

  MasteryLevelEngine({
    LessonProgressTrackerService? progress,
    LessonTrackMetaService? trackMeta,
  })  : _progress = progress ?? LessonProgressTrackerService.instance,
        _trackMeta = trackMeta ?? LessonTrackMetaService.instance;

  Future<MasteryLevel> computeUserLevel() async {
    final completedSteps = await _progress.getCompletedStepsFlat();
    final tracks = const LearningTrackEngine().getTracks();
    var completedTracks = 0;
    for (final t in tracks) {
      final meta = await _trackMeta.load(t.id);
      if (meta?.completedAt != null) {
        completedTracks += 1;
      }
    }

    final stepCount = completedSteps.length;

    // Future enhancement: incorporate EV/ICM metrics from trainings.

    if (stepCount >= 100 && completedTracks >= 3) {
      return MasteryLevel.expert;
    }
    if (stepCount >= 30 || completedTracks >= 1) {
      return MasteryLevel.intermediate;
    }
    return MasteryLevel.beginner;
  }
}
