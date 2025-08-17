import 'package:test/test.dart';
import 'package:poker_analyzer/ui/session_player/models.dart';
import 'package:poker_analyzer/ui/session_player/spot_specs.dart';

void main() {
  group('mvs_player smoke', () {
    test('jam_vs kinds return jam/fold', () {
      for (final k in autoReplayKinds) {
        expect(actionsMap[k], ['jam', 'fold']);
      }
    });

    test('subtitle prefixes non-empty & sane', () {
      const expected = {
        SpotKind.l3_flop_jam_vs_raise: 'Flop Jam vs Raise • ',
        SpotKind.l3_turn_jam_vs_raise: 'Turn Jam vs Raise • ',
        SpotKind.l3_river_jam_vs_raise: 'River Jam vs Raise • ',
        SpotKind.l4_icm_bubble_jam_vs_fold: 'ICM Bubble Jam vs Fold • ',
        SpotKind.l4_icm_ladder_jam_vs_fold: 'ICM FT Ladder Jam vs Fold • ',
        SpotKind.l4_icm_sb_jam_vs_fold: 'ICM SB Jam vs Fold • ',
      };
      for (final k in autoReplayKinds) {
        final p = subtitlePrefix[k];
        expect(p, isNotNull);
        expect(p!.isNotEmpty, true);
        expect(p.startsWith(expected[k]!), true);
      }
    });
  });
}
