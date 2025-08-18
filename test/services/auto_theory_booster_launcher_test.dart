import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'package:poker_analyzer/main.dart';
import 'package:poker_analyzer/services/auto_theory_booster_launcher.dart';
import 'package:poker_analyzer/services/recap_completion_tracker.dart';
import 'package:poker_analyzer/services/theory_boost_trigger_service.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/screens/mini_lesson_screen.dart';
import 'package:poker_analyzer/services/training_session_service.dart';

class _FakeTrigger extends TheoryBoostTriggerService {
  final TheoryMiniLessonNode? lesson;
  _FakeTrigger(this.lesson) : super(tracker: RecapCompletionTracker.instance);
  @override
  Future<TheoryMiniLessonNode?> getBoostCandidate(String tag) async => lesson;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('launches booster when candidate available', (tester) async {
    final lesson = const TheoryMiniLessonNode(
      id: 'l1',
      title: 't',
      content: '',
    );
    final service = AutoTheoryBoosterLauncher(
      trigger: _FakeTrigger(lesson),
      cooldown: Duration.zero,
    );
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => TrainingSessionService(),
        child: MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: SizedBox()),
        ),
      ),
    );

    await RecapCompletionTracker.instance.logCompletion(
      'r1',
      'tag',
      const Duration(seconds: 1),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MiniLessonScreen), findsOneWidget);
    service.dispose();
  });

  testWidgets('respects cooldown', (tester) async {
    final lesson = const TheoryMiniLessonNode(
      id: 'l1',
      title: 't',
      content: '',
    );
    final service = AutoTheoryBoosterLauncher(
      trigger: _FakeTrigger(lesson),
      cooldown: const Duration(seconds: 30),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => TrainingSessionService(),
        child: MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: SizedBox()),
        ),
      ),
    );

    await RecapCompletionTracker.instance.logCompletion(
      'r1',
      'tag',
      const Duration(seconds: 1),
    );
    await tester.pumpAndSettle();
    Navigator.of(navigatorKey.currentContext!).pop();

    await RecapCompletionTracker.instance.logCompletion(
      'r2',
      'tag',
      const Duration(seconds: 1),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MiniLessonScreen), findsNothing);
    service.dispose();
  });
}
