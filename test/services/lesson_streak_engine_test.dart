import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/lesson_streak_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('lesson streak increments and resets', () async {
    SharedPreferences.setMockInitialValues({});
    await LessonStreakEngine.instance.markTodayCompleted();
    var streak = await LessonStreakEngine.instance.getCurrentStreak();
    expect(streak, 1);

    final prefs = await SharedPreferences.getInstance();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yStr =
        '${yesterday.year.toString().padLeft(4, '0')}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
    await prefs.setString('lesson_streak_last_day', yStr);
    await prefs.setInt('lesson_streak_count', 1);

    await LessonStreakEngine.instance.markTodayCompleted();
    streak = await LessonStreakEngine.instance.getCurrentStreak();
    expect(streak, 2);

    final old = DateTime.now().subtract(const Duration(days: 3));
    final oStr =
        '${old.year.toString().padLeft(4, '0')}-${old.month.toString().padLeft(2, '0')}-${old.day.toString().padLeft(2, '0')}';
    await prefs.setString('lesson_streak_last_day', oStr);
    await prefs.setInt('lesson_streak_count', 2);

    streak = await LessonStreakEngine.instance.getCurrentStreak();
    expect(streak, 0);
  });
}
