import 'streak_progress_service.dart';
import 'package:poker_analyzer/services/preferences_service.dart';

class LessonProgressService {
  LessonProgressService._();
  static final instance = LessonProgressService._();

  static String _key(String stepId) => 'lesson_completed_$stepId';

  Future<void> markCompleted(String stepId) async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setBool(_key(stepId), true);
    await StreakProgressService.instance.registerDailyActivity();
  }

  Future<bool> isCompleted(String stepId) async {
    final prefs = await PreferencesService.getInstance();
    return prefs.getBool(_key(stepId)) ?? false;
  }

  Future<Set<String>> getCompletedSteps() async {
    final prefs = await PreferencesService.getInstance();
    final keys = prefs.getKeys().where(
      (k) => k.startsWith('lesson_completed_'),
    );
    return keys.map((k) => k.substring('lesson_completed_'.length)).toSet();
  }
}
