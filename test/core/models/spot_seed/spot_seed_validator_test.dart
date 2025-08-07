import 'package:poker_analyzer/core/models/spot_seed/unified_spot_seed_format.dart';
import 'package:poker_analyzer/core/models/spot_seed/spot_seed_validator.dart';
import 'package:test/test.dart';

void main() {
  final validator = const SpotSeedValidator();

  SpotSeed baseSeed() => SpotSeed(
    id: 's1',
    gameType: 'cash',
    bb: 1,
    stackBB: 20,
    positions: const SpotPositions(hero: 'SB', villain: 'BB'),
    ranges: const SpotRanges(hero: '22+', villain: '55+'),
    board: const SpotBoard(flop: ['Ah', 'Kd', '9c']),
    pot: 1.5,
    tags: const ['tag'],
  );

  test('valid seed passes', () {
    final issues = validator.validate(baseSeed());
    expect(issues, isEmpty);
  });

  test('stackBB <= 0 triggers error', () {
    final seed = baseSeed();
    final bad = SpotSeed(
      id: seed.id,
      gameType: seed.gameType,
      bb: seed.bb,
      stackBB: 0,
      positions: seed.positions,
      ranges: seed.ranges,
      board: seed.board,
      pot: seed.pot,
    );
    final issues = validator.validate(bad);
    expect(issues.where((i) => i.severity == 'error'), isNotEmpty);
  });

  test('tag normalization emits warnings', () {
    final seed = SpotSeed(
      id: 's1',
      gameType: 'cash',
      bb: 1,
      stackBB: 20,
      positions: const SpotPositions(hero: 'SB', villain: 'BB'),
      ranges: const SpotRanges(),
      board: const SpotBoard(),
      pot: 1,
      tags: const ['TAG', 'tag'],
    );
    final issues = validator.validate(seed);
    expect(
      issues.where((i) => i.severity == 'warn').length,
      greaterThanOrEqualTo(1),
    );
  });
}
