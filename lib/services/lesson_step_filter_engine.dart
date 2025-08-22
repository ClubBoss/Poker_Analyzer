import '../models/v3/lesson_step.dart';
import '../models/player_profile.dart';
import '../models/v3/lesson_step_filter.dart';

class LessonStepFilterEngine {
  LessonStepFilterEngine();

  List<LessonStep> applyFilters(
    List<LessonStep> allSteps, {
    required PlayerProfile profile,
  }) {
    return [
      for (final step in allSteps)
        if (_matches(step.filter, profile)) step,
    ];
  }

  bool _matches(LessonStepFilter? filter, PlayerProfile profile) {
    if (filter == null) return true;
    if (filter.minXp != null && profile.xp < filter.minXp!) return false;
    if (filter.gameType != null && profile.gameType != filter.gameType) {
      return false;
    }
    if (filter.skillLevel != null && profile.skillLevel != filter.skillLevel) {
      return false;
    }
    if (filter.tags.isNotEmpty &&
        !filter.tags.every((t) => profile.tags.contains(t))) {
      return false;
    }
    if (filter.completedLessonIds.isNotEmpty &&
        !filter.completedLessonIds.every(
          (id) => profile.completedLessonIds.contains(id),
        )) {
      return false;
    }
    return true;
  }
}
