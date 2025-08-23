import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/app_bootstrap.dart';
import 'package:poker_analyzer/controllers/pack_run_controller.dart';
import 'package:poker_analyzer/models/action_entry.dart';
import 'package:poker_analyzer/models/evaluation_result.dart';
import 'package:poker_analyzer/models/player_model.dart';
import 'package:poker_analyzer/models/training_spot.dart';
import 'package:poker_analyzer/models/training_spot_attempt.dart';
import 'package:poker_analyzer/screens/training_play_screen.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/service_registry.dart';
import 'package:poker_analyzer/services/training_session_controller.dart';
import 'package:poker_analyzer/services/training_session_fingerprint_service.dart';
import 'package:poker_analyzer/models/recall_snippet_result.dart';
import 'package:poker_analyzer/services/user_action_logger.dart';

class _FakeFingerprintService extends TrainingSessionFingerprintService {
  @override
  Future<String> startSession() async => 's1';

  @override
  Future<void> logAttempt(
    TrainingSpotAttempt attempt, {
    List<String> shownTheoryTags = const [],
  }) async {}
}

class _FakePackRunController extends PackRunController {
  _FakePackRunController() : super(packId: 'p1', sessionId: 's1', state: null);

  @override
  Future<RecallSnippetResult?> onResult(
    String spotId,
    bool correct,
    List<String> tags,
  ) async => null;
}

class _FakeTrainingSessionController extends TrainingSessionController {
  final Queue<EvaluationResult> _queue;
  _FakeTrainingSessionController(this._queue)
    : super(registry: ServiceRegistry(), packId: 'p1');

  void setSpot(TrainingSpot spot) => replaySpot(spot);

  @override
  Future<EvaluationResult> evaluateSpot(
    BuildContext context,
    TrainingSpot spot,
    String userAction, {
    int attempts = 3,
  }) async {
    return _queue.removeFirst();
  }
}

TrainingSpot _spot() => TrainingSpot(
  playerCards: const [[], []],
  boardCards: const [],
  actions: const <ActionEntry>[],
  heroIndex: 0,
  numberOfPlayers: 2,
  playerTypes: const [PlayerType.unknown, PlayerType.unknown],
  positions: const ['SB', 'BB'],
  stacks: const [10, 10],
  tags: const ['a'],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TrainingPlayScreen retry after theory', () {
    testWidgets('shows CTA and retries after tap', (tester) async {
      SharedPreferences.setMockInitialValues({
        'auto_retest_after_theory': false,
      });
      await UserActionLogger.instance.load();
      AppBootstrap.testRegistry = ServiceRegistry()
        ..register<TrainingSessionFingerprintService>(
          _FakeFingerprintService(),
        );

      final queue = Queue<EvaluationResult>()
        ..add(
          EvaluationResult(
            correct: false,
            expectedAction: 'FOLD',
            userEquity: 0,
            expectedEquity: 0,
          ),
        )
        ..add(
          EvaluationResult(
            correct: true,
            expectedAction: 'FOLD',
            userEquity: 0,
            expectedEquity: 0,
          ),
        );
      final controller = _FakeTrainingSessionController(queue)
        ..setSpot(_spot());

      final lesson = TheoryMiniLessonNode(
        id: 'l1',
        title: 'L1',
        content: 'c',
        tags: const ['a'],
      );

      await tester.pumpWidget(
        Provider<TrainingSessionController>.value(
          value: controller,
          child: MaterialApp(
            home: TrainingPlayScreen(
              packController: _FakePackRunController(),
              lessonMatchProvider: (_) async => [lesson],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('PUSH'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Learn now (Theory • 1)'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Retry now'), findsOneWidget);
      await tester.tap(find.text('Retry now'));
      await tester.pumpAndSettle();
      expect(find.text('PUSH'), findsOneWidget);

      await tester.tap(find.text('FOLD'));
      await tester.pumpAndSettle();

      final events = UserActionLogger.instance.events;
      expect(
        events.any((e) => e['event'] == 'retest_suggested_after_theory'),
        isTrue,
      );
      expect(
        events.any((e) => e['event'] == 'retest_started_after_theory'),
        isTrue,
      );
      expect(
        events.any(
          (e) =>
              e['event'] == 'retest_outcome_after_theory' &&
              e['success'] == true,
        ),
        isTrue,
      );
    });

    testWidgets('auto-retest triggers instantly', (tester) async {
      SharedPreferences.setMockInitialValues({
        'auto_retest_after_theory': true,
      });
      await UserActionLogger.instance.load();
      AppBootstrap.testRegistry = ServiceRegistry()
        ..register<TrainingSessionFingerprintService>(
          _FakeFingerprintService(),
        );

      final queue = Queue<EvaluationResult>()
        ..add(
          EvaluationResult(
            correct: false,
            expectedAction: 'FOLD',
            userEquity: 0,
            expectedEquity: 0,
          ),
        )
        ..add(
          EvaluationResult(
            correct: true,
            expectedAction: 'FOLD',
            userEquity: 0,
            expectedEquity: 0,
          ),
        );
      final controller = _FakeTrainingSessionController(queue)
        ..setSpot(_spot());

      final lesson = TheoryMiniLessonNode(
        id: 'l1',
        title: 'L1',
        content: 'c',
        tags: const ['a'],
      );

      await tester.pumpWidget(
        Provider<TrainingSessionController>.value(
          value: controller,
          child: MaterialApp(
            home: TrainingPlayScreen(
              packController: _FakePackRunController(),
              lessonMatchProvider: (_) async => [lesson],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('PUSH'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Learn now (Theory • 1)'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Retry now'), findsNothing);
      expect(find.text('PUSH'), findsOneWidget);

      await tester.tap(find.text('FOLD'));
      await tester.pumpAndSettle();

      final events = UserActionLogger.instance.events;
      expect(
        events.any((e) => e['event'] == 'retest_suggested_after_theory'),
        isTrue,
      );
      expect(
        events.any((e) => e['event'] == 'retest_started_after_theory'),
        isTrue,
      );
      expect(
        events.any(
          (e) =>
              e['event'] == 'retest_outcome_after_theory' &&
              e['success'] == true,
        ),
        isTrue,
      );
    });
  });
}
