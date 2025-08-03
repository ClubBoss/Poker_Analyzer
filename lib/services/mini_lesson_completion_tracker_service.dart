import 'package:shared_preferences/shared_preferences.dart';

/// Stores ids of completed theory mini lessons.
class MiniLessonCompletionTrackerService {
  MiniLessonCompletionTrackerService._();
  static final MiniLessonCompletionTrackerService instance =
      MiniLessonCompletionTrackerService._();

  static const String _key = 'theory_lessons_completed';

  Future<void> markCompleted(String lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];
    if (!list.contains(lessonId)) {
      list.add(lessonId);
      await prefs.setStringList(_key, list);
    }
  }

  Future<bool> isCompleted(String lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];
    return list.contains(lessonId);
  }
}
