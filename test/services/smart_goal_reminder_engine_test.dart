import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/goal_engagement.dart';
import 'package:poker_analyzer/models/goal_progress.dart';
import 'package:poker_analyzer/services/smart_goal_reminder_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('returns stale tags ordered by last activity', () async {
    final now = DateTime.now();
    final allGoals = const [
      GoalProgress(tag: 'a', stagesCompleted: 1, averageAccuracy: 50),
      GoalProgress(tag: 'b', stagesCompleted: 2, averageAccuracy: 70),
      GoalProgress(tag: 'c', stagesCompleted: 0, averageAccuracy: 0),
    ];
    final log = [
      GoalEngagement(
        tag: 'a',
        action: 'start',
        timestamp: now.subtract(const Duration(days: 7)),
      ),
      GoalEngagement(
        tag: 'b',
        action: 'dismiss',
        timestamp: now.subtract(const Duration(days: 2)),
      ),
    ];
    const engine = SmartGoalReminderEngine();
    final result = await engine.getStaleGoalTags(
      staleDays: 5,
      allGoals: allGoals,
      engagementLog: log,
    );
    expect(result, ['c', 'a']);
  });

  test('ignores completed goals', () async {
    final now = DateTime.now();
    final allGoals = const [
      GoalProgress(tag: 'done', stagesCompleted: 3, averageAccuracy: 80),
      GoalProgress(tag: 'todo', stagesCompleted: 1, averageAccuracy: 50),
    ];
    final log = [
      GoalEngagement(
        tag: 'done',
        action: 'start',
        timestamp: now.subtract(const Duration(days: 10)),
      ),
    ];
    const engine = SmartGoalReminderEngine();
    final result = await engine.getStaleGoalTags(
      staleDays: 5,
      allGoals: allGoals,
      engagementLog: log,
    );
    expect(result, ['todo']);
  });
}
