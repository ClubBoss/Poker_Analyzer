import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/lesson_goal_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('updateProgress increases counts and resets daily/weekly', () async {
    SharedPreferences.setMockInitialValues({});
    final engine = LessonGoalEngine.instance;
    await engine.updateProgress();

    var daily = await engine.getDailyGoal();
    var weekly = await engine.getWeeklyGoal();
    expect(daily.current, 1);
    expect(weekly.current, 1);

    final prefs = await SharedPreferences.getInstance();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yStr =
        '${yesterday.year.toString().padLeft(4, '0')}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
    await prefs.setString('goal_daily_date', yStr);
    await prefs.setInt('goal_daily_count', 3);

    daily = await engine.getDailyGoal();
    expect(daily.current, 0);

    final lastWeek = DateTime.now().subtract(const Duration(days: 7));
    final lwStart = DateTime(
      lastWeek.year,
      lastWeek.month,
      lastWeek.day,
    ).subtract(Duration(days: lastWeek.weekday - 1));
    final lwStr =
        '${lwStart.year.toString().padLeft(4, '0')}-${lwStart.month.toString().padLeft(2, '0')}-${lwStart.day.toString().padLeft(2, '0')}';
    await prefs.setString('goal_weekly_start', lwStr);
    await prefs.setInt('goal_weekly_count', 10);

    weekly = await engine.getWeeklyGoal();
    expect(weekly.current, 0);
  });
}
