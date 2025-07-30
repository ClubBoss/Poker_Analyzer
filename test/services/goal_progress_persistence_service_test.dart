import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/goal_progress_persistence_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    GoalProgressPersistenceService.instance.resetForTest();
  });

  test('markCompleted persists logs', () async {
    final service = GoalProgressPersistenceService.instance;
    await service.markCompleted('g1', DateTime.utc(2024, 7, 30));
    final todayGoals = await service.getTodayGoals();
    // Should be empty because completion date is in the past.
    expect(todayGoals, isEmpty);

    // Now mark one for today.
    final now = DateTime.now();
    await service.markCompleted('g2', now);
    final loaded = await service.getTodayGoals();
    expect(loaded.length, 1);
    expect(loaded.first.goalId, 'g2');
  });

  test('isCompletedToday works', () async {
    final service = GoalProgressPersistenceService.instance;
    final now = DateTime.now();
    await service.markCompleted('g3', now);
    final result = await service.isCompletedToday('g3');
    expect(result, true);
    final result2 = await service.isCompletedToday('other');
    expect(result2, false);
  });

  test('weekly XP sums completions', () async {
    final service = GoalProgressPersistenceService.instance;
    final now = DateTime.now();
    await service.markCompleted('a', now.subtract(const Duration(days: 1)));
    await service.markCompleted('b', now.subtract(const Duration(days: 2)));
    await service.markCompleted('c', now.subtract(const Duration(days: 8)));
    final xp = await service.getWeeklyXP(xpPerGoal: 10);
    // Only two entries should count (within 7 days)
    expect(xp, 20);
  });
}
