import 'package:shared_preferences/shared_preferences.dart';

class LessonProgressService {
  LessonProgressService._();
  static final instance = LessonProgressService._();

  static String _key(String stepId) => 'lesson_completed_$stepId';

  Future<void> markCompleted(String stepId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(stepId), true);
  }

  Future<bool> isCompleted(String stepId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(stepId)) ?? false;
  }

  Future<Set<String>> getCompletedSteps() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('lesson_completed_'));
    return keys
        .map((k) => k.substring('lesson_completed_'.length))
        .toSet();
  }
}
