import '../models/v3/lesson_track.dart';
import '../models/v3/track_unlock_condition.dart';
import '../models/player_profile.dart';

class TrackUnlockConditionsEngine {
  const TrackUnlockConditionsEngine();

  bool isTrackUnlocked(LessonTrack track, PlayerProfile profile) {
    return _matches(track.unlockCondition, profile);
  }

  bool _matches(TrackUnlockCondition? cond, PlayerProfile profile) {
    if (cond == null) return true;
    if (cond.minXp != null && profile.xp < cond.minXp!) return false;
    if (cond.gameType != null && profile.gameType != cond.gameType) {
      return false;
    }
    if (cond.skillLevel != null && profile.skillLevel != cond.skillLevel) {
      return false;
    }
    if (cond.requiredTags.isNotEmpty &&
        !cond.requiredTags.every((t) => profile.tags.contains(t))) {
      return false;
    }
    if (cond.completedLessonIds.isNotEmpty &&
        !cond.completedLessonIds.every(
          (id) => profile.completedLessonIds.contains(id),
        )) {
      return false;
    }
    return true;
  }
}
