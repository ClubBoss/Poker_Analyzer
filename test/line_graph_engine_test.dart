import 'package:test/test.dart';
import 'package:poker_analyzer/services/line_graph_engine.dart';
import 'package:poker_analyzer/models/line_pattern.dart';
import 'package:poker_analyzer/models/card_model.dart';

void main() {
  test('build creates multi-street hand line from pattern', () {
    final pattern = LinePattern(
      startingPosition: 'btn',
      streets: {
        'flop': ['cbet'],
        'turn': ['check'],
        'river': ['shove'],
      },
    );

    final engine = const LineGraphEngine();
    final result = engine.build(pattern);

    expect(result.heroPosition, 'btn');
    expect(result.streets.length, 3);
    expect(result.streets['flop']!.first.action, 'cbet');
    expect(result.tags, containsAll(['flopCbet', 'turnCheck', 'riverShove']));
  });

  test('expandLine generates spot seeds across streets', () {
    final engine = const LineGraphEngine();
    final board = [
      CardModel(rank: 'A', suit: 's'),
      CardModel(rank: 'K', suit: 'd'),
      CardModel(rank: 'Q', suit: 'h'),
      CardModel(rank: 'J', suit: 'c'),
    ];
    final hand = [
      CardModel(rank: 'T', suit: 's'),
      CardModel(rank: '9', suit: 's'),
    ];

    final seeds = engine.expandLine(
      preflopAction: 'raise-call',
      line: 'check-check-bet',
      board: board,
      hand: hand,
      position: 'btn',
    );

    expect(seeds.length, 2);
    expect(seeds[0].targetStreet, 'flop');
    expect(seeds[0].board.length, 3);
    expect(seeds[0].previousActions, ['raise-call']);
    expect(seeds[1].targetStreet, 'turn');
    expect(seeds[1].board.length, 4);
    expect(seeds[1].previousActions, ['raise-call', 'check', 'check']);
  });
}
