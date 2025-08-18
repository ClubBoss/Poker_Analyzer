import 'package:test/test.dart';
import 'package:poker_analyzer/ui/session_player/models.dart';
import 'package:poker_analyzer/ui/session_player/spot_specs.dart';

void main() {
  group('SpotKind integrity', () {
    test('autoReplayKinds covered by actions & prefixes', () {
      // containsAll работает у Set, а не у Iterable
      expect(actionsMap.keys.toSet().containsAll(autoReplayKinds), true);
      expect(subtitlePrefix.keys.toSet().containsAll(autoReplayKinds), true);
    });

    test('jam_vs actions and expected prefix', () {
      const expected = {
        SpotKind.l3_flop_jam_vs_raise: 'Flop Jam vs Raise • ',
        SpotKind.l3_turn_jam_vs_raise: 'Turn Jam vs Raise • ',
        SpotKind.l3_river_jam_vs_raise: 'River Jam vs Raise • ',
        SpotKind.l4_icm_bubble_jam_vs_fold: 'ICM Bubble Jam vs Fold • ',
        SpotKind.l4_icm_ladder_jam_vs_fold: 'ICM FT Ladder Jam vs Fold • ',
        SpotKind.l4_icm_sb_jam_vs_fold: 'ICM SB Jam vs Fold • ',
      };

      for (final kind in autoReplayKinds) {
        expect(actionsMap[kind], ['jam', 'fold']);
        final p = subtitlePrefix[kind];
        expect(p, isNotNull);
        expect(p!.isNotEmpty, true);
        expect(p.startsWith(expected[kind]!), true);
      }
    });

    test('l4_icm_bb_jam_vs_fold prefix exact match', () {
      expect(
        subtitlePrefix[SpotKind.l4_icm_bb_jam_vs_fold],
        'ICM BB Jam vs Fold • ',
      );
    });

    test('actionsMap vs subtitlePrefix symmetry', () {
      final keys = actionsMap.keys.toSet();
      expect(keys, subtitlePrefix.keys.toSet());
      for (final k in keys) {
        expect(actionsMap[k], ['jam', 'fold']);
        expect(subtitlePrefix[k]!.endsWith(' • '), true);
      }
    });

    test('shouldAutoReplay semantics', () {
      const l3 = [
        SpotKind.l3_flop_jam_vs_raise,
        SpotKind.l3_turn_jam_vs_raise,
        SpotKind.l3_river_jam_vs_raise,
      ];
      const icm = [
        SpotKind.l4_icm_bubble_jam_vs_fold,
        SpotKind.l4_icm_ladder_jam_vs_fold,
        SpotKind.l4_icm_sb_jam_vs_fold,
        SpotKind.l4_icm_bb_jam_vs_fold,
      ];

      for (final k in l3) {
        expect(
          shouldAutoReplay(
            correct: false,
            autoWhy: true,
            kind: k,
            alreadyReplayed: false,
          ),
          true,
        );
      }

      for (final k in icm) {
        expect(
          shouldAutoReplay(
            correct: false,
            autoWhy: true,
            kind: k,
            alreadyReplayed: false,
          ),
          false,
        );
      }

      final k = SpotKind.l3_flop_jam_vs_raise;
      expect(
        shouldAutoReplay(
          correct: true,
          autoWhy: true,
          kind: k,
          alreadyReplayed: false,
        ),
        false,
      );
      expect(
        shouldAutoReplay(
          correct: false,
          autoWhy: false,
          kind: k,
          alreadyReplayed: false,
        ),
        false,
      );
      expect(
        shouldAutoReplay(
          correct: false,
          autoWhy: true,
          kind: k,
          alreadyReplayed: true,
        ),
        false,
      );
    });
  });
}
