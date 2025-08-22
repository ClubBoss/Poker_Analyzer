import '../models/player_profile.dart';
import '../models/v3/lesson_track.dart';
import 'track_unlock_conditions_engine.dart';

/// Filters lesson tracks based on unlock conditions.
class TrackVisibilityFilterEngine {
  TrackVisibilityFilterEngine({
    this.showLockedTracks = false,
    TrackUnlockConditionsEngine? unlockEngine,
  }) : _unlockEngine = unlockEngine ?? const TrackUnlockConditionsEngine();

  final bool showLockedTracks;
  final TrackUnlockConditionsEngine _unlockEngine;

  final Map<String, bool> _cache = {};

  /// Returns only tracks that are unlocked for the given [profile].
  ///
  /// When [showLockedTracks] is `true` all tracks are returned but locked
  /// tracks remain in the list for debug purposes.
  Future<List<LessonTrack>> filterUnlockedTracks(
    List<LessonTrack> allTracks,
    PlayerProfile profile,
  ) async {
    final visible = <LessonTrack>[];
    for (final track in allTracks) {
      final unlocked =
          _cache[track.id] ?? _unlockEngine.isTrackUnlocked(track, profile);
      _cache[track.id] = unlocked;
      if (unlocked || showLockedTracks) {
        visible.add(track);
      }
    }
    return visible;
  }

  /// Clears the cached unlock status for tracks.
  void clearCache() => _cache.clear();
}
