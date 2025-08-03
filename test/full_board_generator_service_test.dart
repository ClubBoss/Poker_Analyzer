import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/card_model.dart';
import 'package:poker_analyzer/services/full_board_generator_service.dart';

void main() {
  test('generates full board without excluded cards', () {
    final svc = FullBoardGeneratorService(random: Random(1));
    final excluded = [CardModel(rank: 'A', suit: '♠')];
    final board = svc.generateBoard(
      FullBoardRequest(stages: 5, excludedCards: excluded),
    );
    expect(board.cards.length, 5);
    expect(board.cards.any((c) => c.rank == 'A' && c.suit == '♠'), isFalse);
  });

  test('generateBoard respects stages and filter', () {
    final svc = FullBoardGeneratorService(random: Random(2));
    final board = svc.generateBoard(
      const FullBoardRequest(
        stages: 3,
        boardFilterParams: {
          'requiredRanks': ['A'],
        },
      ),
    );
    expect(board.flop.length, 3);
    expect(board.turn, isNull);
    expect(board.river, isNull);
    expect(board.flop.any((c) => c.rank == 'A'), isTrue);
  });
}
