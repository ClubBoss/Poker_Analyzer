import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/main.dart';
import 'package:poker_analyzer/models/user_goal.dart';
import 'package:poker_analyzer/services/training_stats_service.dart';
import 'package:poker_analyzer/services/user_goal_engine.dart';
import 'package:poker_analyzer/widgets/user_goal_reengagement_banner.dart';
import 'package:provider/provider.dart';
import 'package:poker_analyzer/screens/training_home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('hidden when no stale goals', (tester) async {
    SharedPreferences.setMockInitialValues({
      'user_goals': UserGoal.encode([]),
      'user_action_log': <String>[],
    });
    final stats = TrainingStatsService();
    final engine = UserGoalEngine(stats: stats);
    await tester.pumpWidget(
      ChangeNotifierProvider<UserGoalEngine>.value(
        value: engine,
        child: const MaterialApp(
          navigatorKey: navigatorKey,
          home: GoalReengagementBanner(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(GoalReengagementBanner), findsOneWidget);
    expect(find.textContaining('Продолжите цель'), findsNothing);
  });

  testWidgets('shows banner for stale goal and resumes', (tester) async {
    final goal = UserGoal(
      id: 'g1',
      title: 'Hands Goal',
      type: 'hands',
      target: 10,
      base: 0,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      tag: 'pushfold',
    );
    final historyEvent = jsonEncode({
      'goalId': 'g1',
      'timestamp':
          DateTime.now().subtract(const Duration(days: 4)).toIso8601String(),
    });
    SharedPreferences.setMockInitialValues({
      'user_goals': UserGoal.encode([goal]),
      'user_action_log': [historyEvent],
    });
    final stats = TrainingStatsService();
    final engine = UserGoalEngine(stats: stats);
    await tester.pumpWidget(
      ChangeNotifierProvider<UserGoalEngine>.value(
        value: engine,
        child: const MaterialApp(
          navigatorKey: navigatorKey,
          home: GoalReengagementBanner(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('pushfold'), findsOneWidget);
    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle();
    expect(find.byType(TrainingHomeScreen), findsOneWidget);
  });
}
