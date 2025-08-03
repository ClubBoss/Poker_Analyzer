import 'package:shared_preferences/shared_preferences.dart';

/// Stores ids of completed theory mini lessons.
class MiniLessonCompletionTrackerService {
  MiniLessonCompletionTrackerService._();
  static final MiniLessonCompletionTrackerService instance =
      MiniLessonCompletionTrackerService._();

  static const String _key = 'theory_lessons_completed';

  Set<String>? _completed;

  Future<void> _ensureLoaded() async {
    if (_completed != null) return;
    final prefs = await SharedPreferences.getInstance();
    _completed = Set<String>.from(prefs.getStringList(_key) ?? <String>[]);
  }

  Future<void> markCompleted(String lessonId) async {
    await _ensureLoaded();
    if (_completed!.add(lessonId)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, _completed!.toList());
    }
  }

  Future<bool> isCompleted(String lessonId) async {
    await _ensureLoaded();
    return _completed!.contains(lessonId);
  }
}
