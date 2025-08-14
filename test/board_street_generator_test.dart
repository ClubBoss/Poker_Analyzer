import 'package:test/test.dart';
import 'package:poker_analyzer/services/autogen_v4.dart';

void main() {
  test('BoardStreetGenerator is deterministic and unique', () {
    const seed = 42;
    const count = 50;
    final gen1 = BoardStreetGenerator(seed: seed);
    final gen2 = BoardStreetGenerator(seed: seed);

    final spots1 = gen1.generate(count: count, preset: 'postflop_default');
    final spots2 = gen2.generate(count: count, preset: 'postflop_default');

    final boards1 = spots1
        .map((s) => (s['board'] as List).cast<String>().join())
        .toList(growable: false);
    final boards2 = spots2
        .map((s) => (s['board'] as List).cast<String>().join())
        .toList(growable: false);

    expect(boards1, boards2, reason: 'deterministic for same seed');
    expect(boards1.toSet().length, count, reason: 'boards are unique');
    expect(spots1.length, count);
  });
}
