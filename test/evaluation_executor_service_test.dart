import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/evaluation_executor_service.dart';
import 'package:poker_analyzer/models/training_spot.dart';
import 'package:poker_analyzer/models/card_model.dart';
import 'package:poker_analyzer/models/action_entry.dart';
import 'package:poker_analyzer/models/eval_request.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/services/evaluation_settings_service.dart';
import 'package:poker_analyzer/services/icm_push_ev_service.dart';
import 'package:poker_analyzer/services/push_fold_ev_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('evaluate returns push for strong hand', () {
    final spot = TrainingSpot(
      playerCards: [
        [CardModel(rank: 'A', suit: '♠'), CardModel(rank: 'K', suit: '♠')],
        [CardModel(rank: '2', suit: '♣'), CardModel(rank: '7', suit: '♦')],
      ],
      boardCards: const [],
      actions: const [],
      heroIndex: 0,
      numberOfPlayers: 2,
      playerTypes: const [],
      positions: const ['BTN', 'BB'],
      stacks: const [10, 10],
      createdAt: DateTime.now(),
    );
    final ctx = TestWidgetsFlutterBinding.instance.renderViewElement!;
    final res = EvaluationExecutorService().evaluateSpot(ctx, spot, 'push');
    expect(res.expectedAction, 'push');
    expect(res.correct, isTrue);
  });

  test('evaluate returns fold for weak hand', () {
    final spot = TrainingSpot(
      playerCards: [
        [CardModel(rank: '3', suit: '♠'), CardModel(rank: '8', suit: '♦')],
        [CardModel(rank: '2', suit: '♣'), CardModel(rank: '7', suit: '♦')],
      ],
      boardCards: const [],
      actions: const [],
      heroIndex: 0,
      numberOfPlayers: 2,
      playerTypes: const [],
      positions: const ['BTN', 'BB'],
      stacks: const [10, 10],
      createdAt: DateTime.now(),
    );
    final ctx = TestWidgetsFlutterBinding.instance.renderViewElement!;
    final res = EvaluationExecutorService().evaluateSpot(ctx, spot, 'push');
    expect(res.expectedAction, 'fold');
    expect(res.correct, isFalse);
  });

  test('evaluate returns call when profitable', () {
    final spot = TrainingSpot(
      playerCards: [
        [CardModel(rank: 'A', suit: '♠'), CardModel(rank: 'K', suit: '♠')],
        [CardModel(rank: '2', suit: '♣'), CardModel(rank: '7', suit: '♦')],
      ],
      boardCards: const [],
      actions: const [
        ActionEntry(0, 1, 'push', amount: 10),
        ActionEntry(0, 0, 'call', amount: 10),
      ],
      heroIndex: 0,
      numberOfPlayers: 2,
      playerTypes: const [],
      positions: const ['BB', 'SB'],
      stacks: const [10, 10],
      createdAt: DateTime.now(),
    );
    final ctx = TestWidgetsFlutterBinding.instance.renderViewElement!;
    final res = EvaluationExecutorService().evaluateSpot(ctx, spot, 'call');
    expect(res.expectedAction, 'call');
    expect(res.correct, isTrue);
  });

  test('evaluate falls back to hero action when stack is deep', () {
    final spot = TrainingSpot(
      playerCards: [
        [CardModel(rank: '5', suit: '♠'), CardModel(rank: '5', suit: '♦')],
        [CardModel(rank: '2', suit: '♣'), CardModel(rank: '7', suit: '♦')],
      ],
      boardCards: const [],
      actions: const [ActionEntry(0, 0, 'call')],
      heroIndex: 0,
      numberOfPlayers: 2,
      playerTypes: const [],
      positions: const ['BTN', 'BB'],
      stacks: const [20, 20],
      createdAt: DateTime.now(),
    );
    final ctx = TestWidgetsFlutterBinding.instance.renderViewElement!;
    final res = EvaluationExecutorService().evaluateSpot(ctx, spot, 'call');
    expect(res.expectedAction, 'call');
    expect(res.correct, isTrue);
  });

  test('async evaluate returns score', () async {
    final spot = TrainingSpot(
      playerCards: [
        [CardModel(rank: 'A', suit: '♠'), CardModel(rank: 'K', suit: '♠')],
        [CardModel(rank: '2', suit: '♣'), CardModel(rank: '7', suit: '♦')],
      ],
      boardCards: const [],
      actions: const [],
      heroIndex: 0,
      numberOfPlayers: 2,
      playerTypes: const [],
      positions: const ['BTN', 'BB'],
      stacks: const [10, 10],
      createdAt: DateTime.now(),
    );
    final req = EvalRequest(hash: 'h', spot: spot, action: 'push');
    final res = await EvaluationExecutorService().evaluate(req);
    expect(res.score, 1);
    final cached = await EvaluationExecutorService().evaluate(req);
    expect(cached.score, 1);
  });

  test('async evaluate returns score for call', () async {
    final spot = TrainingSpot(
      playerCards: [
        [CardModel(rank: 'A', suit: '♠'), CardModel(rank: 'K', suit: '♠')],
        [CardModel(rank: '2', suit: '♣'), CardModel(rank: '7', suit: '♦')],
      ],
      boardCards: const [],
      actions: const [
        ActionEntry(0, 1, 'push', amount: 10),
        ActionEntry(0, 0, 'call', amount: 10),
      ],
      heroIndex: 0,
      numberOfPlayers: 2,
      playerTypes: const [],
      positions: const ['BB', 'SB'],
      stacks: const [10, 10],
      createdAt: DateTime.now(),
    );
    final req = EvalRequest(hash: 'c', spot: spot, action: 'call');
    final res = await EvaluationExecutorService().evaluate(req);
    expect(res.score, 1);
  });

  testWidgets('evaluateSingle uses multiway icm', (tester) async {
    final spot = TrainingPackSpot(
      id: 'm',
      hand: HandData(
        heroCards: 'AA',
        heroIndex: 0,
        playerCount: 3,
        stacks: {'0': 10, '1': 10, '2': 10},
        actions: {
          0: [
            ActionEntry(0, 0, 'push', amount: 10),
            ActionEntry(0, 1, 'call', amount: 10),
            ActionEntry(0, 2, 'call', amount: 10),
          ],
        },
        anteBb: 0,
      ),
    );
    EvaluationSettingsService.instance.update(offline: true);
    await tester.pumpWidget(Container());
    final ctx = tester.element(find.byType(Container));
    await tester.runAsync(() async {
      await EvaluationExecutorService().evaluateSingle(ctx, spot);
    });
    final ev = computePushEV(
      heroBbStack: 10,
      bbCount: 2,
      heroHand: 'AA',
      anteBb: 0,
    );
    final icm = computeMultiwayIcmEV(
      chipStacksBb: const [10, 10, 10],
      heroIndex: 0,
      chipPushEv: ev,
      callerIndices: const [1, 2],
    );
    expect(spot.heroIcmEv, icm);
  });
}
