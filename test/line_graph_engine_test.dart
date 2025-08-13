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

    final engine = LineGraphEngine();
    final result = engine.build(pattern);

    expect(result.heroPosition, 'btn');
    expect(result.streets.length, 3);
    expect(result.streets['flop']!.first.action, 'cbet');
    expect(result.tags, containsAll(['flopCbet', 'turnCheck', 'riverShove']));
  });

  test('expandLine generates tagged spot seeds across streets', () {
    final engine = LineGraphEngine();
    final board = [
      CardModel(rank: 'A', suit: 's'),
      CardModel(rank: 'K', suit: 'd'),
      CardModel(rank: 'Q', suit: 'h'),
      CardModel(rank: 'J', suit: 'c'),
      CardModel(rank: 'T', suit: 'd'),
    ];
    final hand = [
      CardModel(rank: 'T', suit: 's'),
      CardModel(rank: '9', suit: 's'),
    ];

    final seeds = engine.expandLine(
      preflopAction: 'raise-call',
      line: 'cbet-check-shove',
      board: board,
      hand: hand,
      position: 'btn',
    );

    expect(seeds.length, 3);
    expect(seeds[0].targetStreet, 'flop');
    expect(seeds[0].board.length, 3);
    expect(seeds[0].previousActions, ['raise-call']);
    expect(seeds[0].tags, contains('flopCbet'));

    expect(seeds[1].targetStreet, 'turn');
    expect(seeds[1].board.length, 4);
    expect(seeds[1].previousActions, ['raise-call', 'cbet']);
    expect(seeds[1].tags, containsAll(['flopCbet', 'turnCheck']));

    expect(seeds[2].targetStreet, 'river');
    expect(seeds[2].board.length, 5);
    expect(seeds[2].previousActions, ['raise-call', 'cbet', 'check']);
    expect(seeds[2].tags, containsAll(['flopCbet', 'turnCheck', 'riverShove']));
  });
}
