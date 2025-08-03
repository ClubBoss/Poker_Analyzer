
/// Represents the state of a milestone stage within a track.
enum MilestoneState { locked, unlocked, completed }

/// Handles unlocking of milestone stages for a skill track.
class TrackMilestoneUnlockerService {
  TrackMilestoneUnlockerService._();
  static final TrackMilestoneUnlockerService instance =
      TrackMilestoneUnlockerService._();

  static String _key(String trackId) => 'track_${trackId}_unlocked_stage';

  /// Ensures a milestone entry exists for [trackId] with stage 0 unlocked.
  Future<void> initializeMilestones(String trackId) async {
    final prefs = await PreferencesService.getInstance();
    final key = _key(trackId);
    if (!prefs.containsKey(key)) {
      await prefs.setInt(key, 0);
    }
  }

  /// Returns the highest stage index unlocked for [trackId].
  Future<int> getHighestUnlockedStage(String trackId) async {
    final prefs = await PreferencesService.getInstance();
    return prefs.getInt(_key(trackId)) ?? 0;
  }

  /// Unlocks the next stage for [trackId].
  Future<void> unlockNextStage(String trackId) async {
    final prefs = await PreferencesService.getInstance();
    final key = _key(trackId);
    final current = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, current + 1);
  }

  /// Returns milestone states for stages [0..totalStages-1] of [trackId].
  Future<Map<int, MilestoneState>> getMilestoneStates({
    required String trackId,
    required int totalStages,
    required Set<int> completedStages,
  }) async {
    final highest = await getHighestUnlockedStage(trackId);
    final map = <int, MilestoneState>{};
    for (var i = 0; i < totalStages; i++) {
      if (completedStages.contains(i)) {
        map[i] = MilestoneState.completed;
      } else if (i <= highest) {
        map[i] = MilestoneState.unlocked;
      } else {
        map[i] = MilestoneState.locked;
      }
    }
    return map;
  }
}
