import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/full_board_generator.dart';

void main() {
  test('generates boards matching constraints', () {
    const generator = FullBoardGenerator();
    final boards = generator.generate({
      'paired': true,
      'aceHigh': true,
      'rainbow': true,
      'drawy': true,
      'requiredRanks': ['A', 'K'],
      'requiredSuits': ['♠', '♥', '♦'],
    });
    // There should be exactly 6 flops matching these filters.
    // Each flop has 1176 turn/river combinations.
    expect(boards.length, 6 * 1176);
    // Ensure uniqueness
    final unique = {
      for (final b in boards) [...b.flop, b.turn, b.river].join(' ')
    };
    expect(unique.length, boards.length);
  });
}
