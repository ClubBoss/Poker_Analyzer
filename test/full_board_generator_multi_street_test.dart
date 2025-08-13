import 'dart:math';

import 'package:test/test.dart';

import 'package:poker_analyzer/services/full_board_generator.dart';

void main() {
  test('generates flop only when targetStreet is flop', () {
    final generator = FullBoardGenerator(random: Random(1));
    final board = generator.generate(targetStreet: 'flop');
    expect(board.flop.length, 3);
    expect(board.turn, isNull);
    expect(board.river, isNull);
    final all = board.cards.map((c) => c.toString()).toSet();
    expect(all.length, 3);
  });

  test('generates full board with constraints', () {
    final generator = FullBoardGenerator(random: Random(2));
    final board = generator.generate(boardConstraints: {'low': true});
    expect(board.flop.length, 3);
    expect(board.turn, isNotNull);
    expect(board.river, isNotNull);
    bool isLow(String rank) {
      const order = ['2', '3', '4', '5', '6', '7', '8'];
      return order.contains(rank);
    }

    expect(board.cards.every((c) => isLow(c.rank)), isTrue);
  });

  test('re-rolls until constraints satisfied', () {
    final generator = FullBoardGenerator(random: Random(3));
    final board = generator.generate(
      boardConstraints: {
        'requiredRanks': ['A', 'K', 'Q'],
      },
    );
    expect(generator.lastAttempts, greaterThan(1));
    final ranks = board.flop.map((c) => c.rank.toUpperCase()).toSet();
    expect(ranks.containsAll(['A', 'K', 'Q']), isTrue);
  });
}
