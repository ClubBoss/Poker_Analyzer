import 'package:test/test.dart';
import 'package:poker_analyzer/services/line_graph_engine.dart';
import 'package:poker_analyzer/models/spot_seed_format.dart';
import 'package:poker_analyzer/models/card_model.dart';

void main() {
  test('build extracts normalized actions by street', () {
    final seed = SpotSeedFormat(
      player: 'hero',
      handGroup: const ['broadways'],
      position: 'btn',
      board: [
        CardModel(rank: '2', suit: 'h'),
        CardModel(rank: '2', suit: 'c'),
        CardModel(rank: '9', suit: 'd'),
      ],
      villainActions: const ['bet 50', 'call'],
    );
    final engine = const LineGraphEngine();
    final graph = engine.build(seed);
    expect(graph.heroPosition, 'btn');
    expect(graph.streets.length, 1);
    final street = graph.streets.first;
    expect(street.street, 'flop');
    expect(street.actions.map((a) => a.action).toList(), ['bet', 'call']);
    expect(street.actions.every((a) => a.position == 'villain'), isTrue);
  });
}
