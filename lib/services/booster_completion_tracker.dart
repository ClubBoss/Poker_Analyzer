
/// Tracks completed boosters to avoid reinjecting them.
class BoosterCompletionTracker {
  BoosterCompletionTracker._();
  static final BoosterCompletionTracker instance = BoosterCompletionTracker._();

  static const String _prefsKey = 'completed_boosters';

  final Set<String> _completed = <String>{};
  bool _loaded = false;

  /// Clears cached data for tests.
  void resetForTest() {
    _loaded = false;
    _completed.clear();
  }

  Future<void> _load() async {
    if (_loaded) return;
    final prefs = await PreferencesService.getInstance();
    _completed.addAll(prefs.getStringList(_prefsKey)?.toSet() ?? <String>{});
    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setStringList(_prefsKey, _completed.toList());
  }

  /// Marks [boosterId] as completed.
  Future<void> markBoosterCompleted(String boosterId) async {
    if (boosterId.isEmpty) return;
    await _load();
    if (_completed.add(boosterId)) {
      await _save();
    }
  }

  /// Whether [boosterId] has been completed.
  Future<bool> isBoosterCompleted(String boosterId) async {
    if (boosterId.isEmpty) return false;
    await _load();
    return _completed.contains(boosterId);
  }

  /// All completed booster ids.
  Future<Set<String>> getAllCompletedBoosters() async {
    await _load();
    return Set<String>.from(_completed);
  }
}
