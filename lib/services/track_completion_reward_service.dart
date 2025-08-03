
/// Persists a flag that a track completion reward has been granted.
class TrackCompletionRewardService {
  TrackCompletionRewardService._();
  static final TrackCompletionRewardService instance =
      TrackCompletionRewardService._();

  /// Grants reward for [trackId].
  /// Returns `true` if the reward was granted for the first time.
  Future<bool> grantReward(String trackId) async {
    if (trackId.isEmpty) return false;
    final prefs = await PreferencesService.getInstance();
    final key = 'reward_granted_$trackId';
    if (prefs.getBool(key) ?? false) return false;
    await prefs.setBool(key, true);
    return true;
  }
}
