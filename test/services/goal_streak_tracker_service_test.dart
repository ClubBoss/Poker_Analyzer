import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/goal_progress_persistence_service.dart';
import 'package:poker_analyzer/services/goal_streak_tracker_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    GoalProgressPersistenceService.instance.resetForTest();
    await GoalStreakTrackerService.instance.resetForTest();
  });

  test('streak increments with consecutive days', () async {
    final persist = GoalProgressPersistenceService.instance;
    final tracker = GoalStreakTrackerService.instance;
    final now = DateTime.now();
    await persist.markCompleted('a', now.subtract(const Duration(days: 2)));
    await persist.markCompleted('b', now.subtract(const Duration(days: 1)));
    await persist.markCompleted('c', now);

    final info = await tracker.getStreakInfo();
    expect(info.currentStreak, 3);
    expect(info.longestStreak, 3);
  });

  test('streak resets when day missed', () async {
    final persist = GoalProgressPersistenceService.instance;
    final tracker = GoalStreakTrackerService.instance;
    final now = DateTime.now();
    await persist.markCompleted('a', now.subtract(const Duration(days: 2)));
    final info = await tracker.getStreakInfo();
    expect(info.currentStreak, 0);
    expect(info.longestStreak, 1);
  });
}
