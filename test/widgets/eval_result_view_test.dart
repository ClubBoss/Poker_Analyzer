import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/card_model.dart';
import 'package:poker_analyzer/models/training_spot.dart';
import 'package:poker_analyzer/widgets/eval_result_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows score from EvalResult', (WidgetTester tester) async {
    final spot = TrainingSpot(
      playerCards: [
        [
          const CardModel(rank: 'A', suit: '♠'),
          const CardModel(rank: 'K', suit: '♠')
        ],
        [
          const CardModel(rank: '2', suit: '♣'),
          const CardModel(rank: '7', suit: '♦')
        ],
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
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: EvalResultView(spot: spot, action: 'push')),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Score:'), findsOneWidget);
  });
}
