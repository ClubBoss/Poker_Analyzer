import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/widgets/smart_goal_progress_bar.dart';
import 'package:poker_analyzer/services/goal_progress_persistence_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    GoalProgressPersistenceService.instance.resetForTest();
  });

  testWidgets('shows weekly XP progress', (tester) async {
    final service = GoalProgressPersistenceService.instance;
    final now = DateTime.now();
    await service.markCompleted('a', now.subtract(const Duration(days: 1)));
    await service.markCompleted('b', now.subtract(const Duration(days: 2)));

    await tester.pumpWidget(
        const MaterialApp(home: SmartGoalProgressBar(weeklyTarget: 100)));
    await tester.pump();

    expect(find.text('50/100 XP this week'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  testWidgets('shows badge when goal reached', (tester) async {
    final service = GoalProgressPersistenceService.instance;
    final now = DateTime.now();
    await service.markCompleted('a', now);
    await service.markCompleted('b', now);
    await service.markCompleted('c', now);
    await service.markCompleted('d', now);

    await tester.pumpWidget(
        const MaterialApp(home: SmartGoalProgressBar(weeklyTarget: 100)));
    await tester.pump();

    expect(find.text('100/100 XP this week'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });
}
