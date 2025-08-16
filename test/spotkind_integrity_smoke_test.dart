import 'package:test/test.dart';
import 'package:poker_analyzer/ui/session_player/spot_specs.dart';
import 'package:poker_analyzer/ui/session_player/models.dart';

void main() {
  group('SpotKind integrity', () {
    test('jam_vs actions and prefixes', () {
      const expectedPrefixes = {
        SpotKind.l3_flop_jam_vs_raise: 'Flop Jam vs Raise • ',
        SpotKind.l3_turn_jam_vs_raise: 'Turn Jam vs Raise • ',
        SpotKind.l3_river_jam_vs_raise: 'River Jam vs Raise • ',
        SpotKind.l4_icm_bubble_jam_vs_fold: 'ICM Bubble Jam vs Fold • ',
        SpotKind.l4_icm_ladder_jam_vs_fold: 'ICM FT Ladder Jam vs Fold • ',
        SpotKind.l4_icm_sb_jam_vs_fold: 'ICM SB Jam vs Fold • ',
      };
      for (final kind in autoReplayKinds) {
        expect(actionsMap[kind], ['jam', 'fold']);
        final prefix = subtitlePrefix[kind];
        expect(prefix, isNotNull);
        expect(prefix!.isNotEmpty, true);
        expect(prefix.startsWith(expectedPrefixes[kind]!), true);
      }
    });

    test('autoReplayKinds covered', () {
      expect(actionsMap.keys.toSet().containsAll(autoReplayKinds), true);
      expect(subtitlePrefix.keys.toSet().containsAll(autoReplayKinds), true);
    });
  });
}
