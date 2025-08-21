import 'package:poker_analyzer/core/models/spot_seed/unified_spot_seed_format.dart';
import 'package:poker_analyzer/core/models/spot_seed/spot_seed_codec.dart';
import 'package:test/test.dart';

void main() {
  final codec = const SpotSeedCodec();

  SpotSeed buildSeed() => SpotSeed(
    id: 's1',
    gameType: 'cash',
    bb: 1,
    stackBB: 20,
    positions: const SpotPositions(hero: 'SB', villain: 'BB'),
    ranges: const SpotRanges(hero: '22+', villain: '55+'),
    board: const SpotBoard(flop: ['Ah', 'Kd', '9c']),
    pot: 1.5,
    tags: const ['test'],
    difficulty: 'easy',
    audience: 'public',
  );

  test('round trip json/yaml', () {
    final seed = buildSeed();
    final yaml = codec.toYaml(seed);
    final decoded = codec.fromYaml(yaml);
    expect(codec.toJson(decoded), equals(codec.toJson(seed)));
  });
}
