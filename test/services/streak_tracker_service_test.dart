import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/streak_tracker_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('streak increments on consecutive days', () async {
    SharedPreferences.setMockInitialValues({});
    final service = StreakTrackerService.instance;
    final milestone1 = await service.markActiveToday();
    var current = await service.getCurrentStreak();
    var best = await service.getBestStreak();
    expect(current, 1);
    expect(best, 1);
    expect(milestone1, false);

    final prefs = await SharedPreferences.getInstance();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    await prefs.setString('lastActiveDate', yesterday.toIso8601String());
    await prefs.setInt('currentStreak', 1);
    await prefs.setInt('bestStreak', 3);

    final milestone2 = await service.markActiveToday();
    current = await service.getCurrentStreak();
    best = await service.getBestStreak();
    expect(current, 2);
    expect(best, 3);
    expect(milestone2, false);

    final old = DateTime.now().subtract(const Duration(days: 3));
    await prefs.setString('lastActiveDate', old.toIso8601String());
    await prefs.setInt('currentStreak', 2);

    current = await service.getCurrentStreak();
    best = await service.getBestStreak();
    expect(current, 0);
    expect(best, 3);
  });

  test('milestone detected correctly', () async {
    SharedPreferences.setMockInitialValues({});
    final service = StreakTrackerService.instance;
    // Day 1
    await service.markActiveToday();
    final prefs = await SharedPreferences.getInstance();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    await prefs.setString('lastActiveDate', yesterday.toIso8601String());
    await prefs.setInt('currentStreak', 1);
    // Day 2
    await service.markActiveToday();
    final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
    await prefs.setString('lastActiveDate', twoDaysAgo.toIso8601String());
    await prefs.setInt('currentStreak', 2);
    // Day 3 should hit milestone
    final milestone = await service.markActiveToday();
    expect(milestone, true);
  });
}
