
/// Available learning track profiles for players.
enum GameModeProfile { cashOnline, cashLive, mttOnline, mttLive }

/// Provides access to the current [GameModeProfile] and persists it across app launches.
class GameModeProfileEngine {
  GameModeProfileEngine._();

  static final GameModeProfileEngine instance = GameModeProfileEngine._();

  static const _prefsKey = 'active_game_mode_profile';

  GameModeProfile _active = GameModeProfile.cashOnline;
  bool _loaded = false;

  /// Loads the active profile from persistent storage.
  Future<void> load() async {
    final prefs = await PreferencesService.getInstance();
    final idx = prefs.getInt(_prefsKey);
    if (idx != null && idx >= 0 && idx < GameModeProfile.values.length) {
      _active = GameModeProfile.values[idx];
    }
    _loaded = true;
  }

  /// Returns the current active profile.
  GameModeProfile getActiveProfile() {
    if (!_loaded) {
      throw StateError('GameModeProfileEngine not loaded');
    }
    return _active;
  }

  /// Sets [profile] as the active profile and persists it.
  Future<void> setActiveProfile(GameModeProfile profile) async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setInt(_prefsKey, profile.index);
    _active = profile;
  }

  /// Returns all profiles currently available to the user.
  List<GameModeProfile> getAvailableProfiles() =>
      List.unmodifiable(GameModeProfile.values);
}

