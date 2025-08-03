import 'package:test/test.dart';
import 'package:poker_analyzer/services/line_graph_engine.dart';
import 'package:poker_analyzer/models/line_pattern.dart';

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
}
