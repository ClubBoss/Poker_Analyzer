import 'package:test/test.dart';

import '../lib/ui/session_player/spot_specs.dart';
import '../lib/ui/session_player/models.dart';

void main() {
  group('isJamFold helper', () {
    test('Exact set match', () {
      final jamFoldKinds = {
        for (final k in SpotKind.values)
          if (isJamFold(k)) k,
      };
      expect(
        jamFoldKinds,
        unorderedEquals({
          SpotKind.l3_flop_jam_vs_raise,
          SpotKind.l3_turn_jam_vs_raise,
          SpotKind.l3_river_jam_vs_raise,
          SpotKind.l4_icm_bubble_jam_vs_fold,
          SpotKind.l4_icm_ladder_jam_vs_fold,
          SpotKind.l4_icm_sb_jam_vs_fold,
        }),
      );
    });

    test('Equivalence with actionsMap', () {
      final fromHelper = {
        for (final k in SpotKind.values)
          if (isJamFold(k)) k,
      };
      final fromMap = {
        for (final entry in actionsMap.entries)
          if (entry.value.length == 2 &&
              entry.value[0] == 'jam' &&
              entry.value[1] == 'fold')
            entry.key,
      };
      expect(fromHelper, fromMap);
    });

    test('Subtitle sanity', () {
      const l3Kinds = {
        SpotKind.l3_flop_jam_vs_raise,
        SpotKind.l3_turn_jam_vs_raise,
        SpotKind.l3_river_jam_vs_raise,
      };
      const l4Kinds = {
        SpotKind.l4_icm_bubble_jam_vs_fold,
        SpotKind.l4_icm_ladder_jam_vs_fold,
        SpotKind.l4_icm_sb_jam_vs_fold,
      };

      for (final k in SpotKind.values.where(isJamFold)) {
        final prefix = subtitlePrefix[k];
        expect(prefix, isNotNull);
        expect(prefix!.isNotEmpty, true);
        if (l3Kinds.contains(k)) {
          expect(prefix.contains('Jam vs Raise • '), true);
        } else if (l4Kinds.contains(k)) {
          expect(prefix.startsWith('ICM '), true);
        }
      }
    });
  });
}
