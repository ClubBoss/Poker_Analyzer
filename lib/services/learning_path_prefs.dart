
class LearningPathPrefs {
  static const _skipPreviewKey = 'learning_skip_preview_if_ready';

  bool _skipPreviewIfReady = true;

  bool get skipPreviewIfReady => _skipPreviewIfReady;

  LearningPathPrefs._();

  static final instance = LearningPathPrefs._();

  Future<void> load() async {
    final prefs = await PreferencesService.getInstance();
    _skipPreviewIfReady = prefs.getBool(_skipPreviewKey) ?? true;
  }

  Future<void> setSkipPreviewIfReady(bool value) async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setBool(_skipPreviewKey, value);
    _skipPreviewIfReady = value;
  }
}
