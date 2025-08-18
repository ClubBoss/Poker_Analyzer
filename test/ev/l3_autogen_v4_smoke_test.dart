import 'package:test/test.dart';

import 'package:poker_analyzer/l3/autogen_v4/board_street_generator.dart';

void main() {
  group('l3 autogen v4 smoke', () {
    const seeds = [1337, 9001, 424242];
    const count = 40;
    const mix = TargetMix.mvsDefault();

    for (final seed in seeds) {
      test('seed ' + seed.toString() + ' deterministic and mix', () {
        final spots = generateSpots(seed: seed, count: count, mix: mix);
        expect(spots.length, inInclusiveRange(30, 50));
        expect(spots, isNotEmpty);

        final h1 = itemsHash(spots, 10);
        final h2 = itemsHash(
          generateSpots(seed: seed, count: count, mix: mix),
          10,
        );
        expect(h1, h2);

        final streetCounts = {Street.flop: 0, Street.turn: 0, Street.river: 0};
        final posCounts = {Position.ip: 0, Position.oop: 0};
        final sprCounts = {SprBin.short: 0, SprBin.mid: 0, SprBin.deep: 0};

        for (final s in spots) {
          streetCounts[s.street] = streetCounts[s.street]! + 1;
          posCounts[s.pos] = posCounts[s.pos]! + 1;
          sprCounts[s.sprBin] = sprCounts[s.sprBin]! + 1;
        }

        void assertMix(Map counts, Map pct) {
          counts.forEach((key, value) {
            final double target = pct[key]!;
            final realized = value / spots.length;
            expect((realized - target).abs(), lessThanOrEqualTo(0.15));
            if (target > 0) {
              expect(value, greaterThan(0));
            }
          });
        }

        assertMix(streetCounts, mix.streetPct);
        assertMix(posCounts, mix.posPct);
        assertMix(sprCounts, mix.sprPct);
      });
    }
  });
}
