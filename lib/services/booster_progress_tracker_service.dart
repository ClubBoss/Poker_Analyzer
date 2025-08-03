
/// Tracks play progress for booster packs.
class BoosterProgressTrackerService {
  BoosterProgressTrackerService._();
  static final instance = BoosterProgressTrackerService._();

  static const _progressPrefix = 'progress_tpl_';
  static const _completedPrefix = 'completed_tpl_';

  Future<int?> getLastIndex(String boosterId) async {
    final prefs = await PreferencesService.getInstance();
    return prefs.getInt('$_progressPrefix$boosterId');
  }

  Future<void> setLastIndex(String boosterId, int index) async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setInt('$_progressPrefix$boosterId', index);
  }

  Future<void> clearProgress(String boosterId) async {
    final prefs = await PreferencesService.getInstance();
    await prefs.remove('$_progressPrefix$boosterId');
  }

  Future<bool> isCompleted(String boosterId) async {
    final prefs = await PreferencesService.getInstance();
    return prefs.getBool('$_completedPrefix$boosterId') ?? false;
  }

  Future<Map<String, int>> getAllProgress() async {
    final prefs = await PreferencesService.getInstance();
    final result = <String, int>{};
    for (final k in prefs.getKeys()) {
      if (k.startsWith(_progressPrefix)) {
        final id = k.substring(_progressPrefix.length);
        final idx = prefs.getInt(k);
        if (idx != null) result[id] = idx;
      }
    }
    return result;
  }
}
