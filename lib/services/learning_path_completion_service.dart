
class LearningPathCompletionService {
  LearningPathCompletionService._();
  static final instance = LearningPathCompletionService._();

  static const _completedKey = 'learning_path_completed';
  static const _dateKey = 'learning_path_completed_at';

  Future<bool> isPathCompleted() async {
    final prefs = await PreferencesService.getInstance();
    return prefs.getBool(_completedKey) ?? false;
  }

  Future<void> markPathCompleted() async {
    final prefs = await PreferencesService.getInstance();
    final already = prefs.getBool(_completedKey) ?? false;
    if (already) return;
    await prefs.setBool(_completedKey, true);
    await prefs.setString(_dateKey, DateTime.now().toIso8601String());
  }

  Future<DateTime?> getCompletionDate() async {
    final prefs = await PreferencesService.getInstance();
    final raw = prefs.getString(_dateKey);
    return raw != null ? DateTime.tryParse(raw) : null;
  }
}
