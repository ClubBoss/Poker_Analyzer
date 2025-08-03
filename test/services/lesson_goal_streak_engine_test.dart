import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/lesson_goal_streak_engine.dart';
import 'package:poker_analyzer/utils/date_key_formatter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('goal streak increments and resets', () async {
    SharedPreferences.setMockInitialValues({});
    final engine = LessonGoalStreakEngine.instance;
    await engine.updateStreakOnGoalCompletion();
    var current = await engine.getCurrentStreak();
    var best = await engine.getBestStreak();
    expect(current, 1);
    expect(best, 1);

    final prefs = await SharedPreferences.getInstance();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yStr = DateKeyFormatter.format(yesterday);
    await prefs.setString('goal_streak_last_date', yStr);
    await prefs.setInt('goal_streak_count', 1);
    await prefs.setInt('goal_streak_best', 3);

    await engine.updateStreakOnGoalCompletion();
    current = await engine.getCurrentStreak();
    best = await engine.getBestStreak();
    expect(current, 2);
    expect(best, 3);

    final old = DateTime.now().subtract(const Duration(days: 3));
    final oStr = DateKeyFormatter.format(old);
    await prefs.setString('goal_streak_last_date', oStr);
    await prefs.setInt('goal_streak_count', 2);
    await prefs.setInt('goal_streak_best', 3);

    current = await engine.getCurrentStreak();
    best = await engine.getBestStreak();
    expect(current, 0);
    expect(best, 3);
  });
}
