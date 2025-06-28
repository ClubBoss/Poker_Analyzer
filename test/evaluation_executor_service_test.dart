import 'package:flutter_test/flutter_test.dart';
import 'package:poker_ai_analyzer/services/evaluation_executor_service.dart';
import 'package:poker_ai_analyzer/models/training_spot.dart';
import 'package:poker_ai_analyzer/models/card_model.dart';
import 'package:poker_ai_analyzer/models/action_entry.dart';

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
    final res = EvaluationExecutorService().evaluate(ctx, spot, 'push');
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
    final res = EvaluationExecutorService().evaluate(ctx, spot, 'push');
    expect(res.expectedAction, 'fold');
    expect(res.correct, isFalse);
  });
}
