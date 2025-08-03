import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/card_model.dart';
import 'package:poker_analyzer/models/spot_seed_format.dart';
import 'package:poker_analyzer/services/line_graph_engine.dart';
import 'package:poker_analyzer/services/full_board_generator_service.dart';

void main() {
  test('generates sequential spots preserving hero and board', () {
    final root = SpotSeedFormat(
      player: 'hero',
      handGroup: ['AKs'],
      position: 'btn',
      board: [
        CardModel(rank: 'A', suit: '♠'),
        CardModel(rank: 'K', suit: '♥'),
        CardModel(rank: 'Q', suit: '♦'),
      ],
      villainActions: ['check', 'bet', 'call'],
    );

    final engine = LineGraphEngine(
      boardGenerator: FullBoardGeneratorService(random: Random(1)),
    );

    final spots = engine.generate(
      LineGraphRequest(root: root, stages: 3, config: const LineGraphConfig()),
    );

    expect(spots.length, 3);
    for (final s in spots) {
      expect(s.player, root.player);
      expect(s.handGroup, root.handGroup);
      expect(s.position, root.position);
    }
    expect(spots[0].board.length, 3);
    expect(spots[1].board.length, 4);
    expect(spots[2].board.length, 5);
    expect(spots[1].board.sublist(0, 3), root.board);
    expect(spots[2].board.sublist(0, 4), spots[1].board);
    expect(spots[0].villainActions, ['check']);
    expect(spots[1].villainActions, ['check', 'bet']);
    expect(spots[2].villainActions, ['check', 'bet', 'call']);
  });
}
