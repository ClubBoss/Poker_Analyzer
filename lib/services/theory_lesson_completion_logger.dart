import 'package:shared_preferences/shared_preferences.dart';

/// Logs completion timestamps for theory mini lessons.
class TheoryLessonCompletionLogger {
  TheoryLessonCompletionLogger._();
  static final TheoryLessonCompletionLogger instance =
      TheoryLessonCompletionLogger._();

  static const String _prefix = 'lesson_completed_at_';

  /// Marks [lessonId] as completed with current timestamp.
  Future<void> markCompleted(String lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefix$lessonId',
      DateTime.now().toIso8601String(),
    );
  }

  /// Returns true if [lessonId] was previously completed.
  Future<bool> isCompleted(String lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('$_prefix$lessonId');
  }

  /// Returns map of completed lesson ids and their completion timestamps.
  Future<Map<String, DateTime>> getCompletedLessons() async {
    final prefs = await SharedPreferences.getInstance();
    final result = <String, DateTime>{};
    for (final key in prefs.getKeys()) {
      if (key.startsWith(_prefix)) {
        final id = key.substring(_prefix.length);
        final ts = prefs.getString(key);
        if (ts != null) {
          final time = DateTime.tryParse(ts);
          if (time != null) {
            result[id] = time;
          }
        }
      }
    }
    return result;
  }
}

