import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/player_profile.dart';
import '../models/v3/lesson_step.dart';
import '../models/v3/lesson_track.dart';
import 'lesson_loader_service.dart';
import 'lesson_progress_service.dart';
import 'lesson_step_filter_engine.dart';
import 'learning_track_engine.dart';

/// Suggests the most relevant unfinished lesson step to resume.
class LessonResumeEngine {
  const LessonResumeEngine();

  Future<LessonStep?> getResumeStep(PlayerProfile profile) async {
    final steps = await LessonLoaderService.instance.loadAllLessons();
    final filtered = const LessonStepFilterEngine().applyFilters(
      steps,
      profile: profile,
    );
    final completed = await LessonProgressService.instance.getCompletedSteps();

    final prefs = await SharedPreferences.getInstance();
    final trackId = prefs.getString('lesson_selected_track');
    LessonTrack? track;
    if (trackId != null) {
      track = const LearningTrackEngine().getTracks().firstWhereOrNull(
            (t) => t.id == trackId,
          );
    }

    if (track != null) {
      for (final id in track.stepIds) {
        if (!completed.contains(id)) {
          final step = filtered.firstWhereOrNull((s) => s.id == id);
          if (step != null) return step;
        }
      }
    }

    for (final step in filtered) {
      if (!completed.contains(step.id)) return step;
    }
    return null;
  }
}
