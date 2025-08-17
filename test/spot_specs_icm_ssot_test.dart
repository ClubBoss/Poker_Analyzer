import 'package:test/test.dart';

import '../lib/ui/session_player/spot_specs.dart';
import '../lib/ui/session_player/models.dart';

void main() {
  group('L4 ICM jam vs fold SSOT', () {
    test('Enum tail stays L4 ICM SB', () {
      expect(SpotKind.values.last, SpotKind.l4_icm_sb_jam_vs_fold);
    });

    test('Actions invariant', () {
      for (final k in {
        SpotKind.l4_icm_bubble_jam_vs_fold,
        SpotKind.l4_icm_ladder_jam_vs_fold,
        SpotKind.l4_icm_sb_jam_vs_fold,
      }) {
        expect(actionsMap[k], ['jam', 'fold']);
      }
    });

    test('Subtitle invariant', () {
      for (final k in {
        SpotKind.l4_icm_bubble_jam_vs_fold,
        SpotKind.l4_icm_ladder_jam_vs_fold,
        SpotKind.l4_icm_sb_jam_vs_fold,
      }) {
        final prefix = subtitlePrefix[k];
        expect(prefix, isNotNull);
        expect(prefix!.isNotEmpty, true);
        expect(prefix.startsWith('ICM '), true);
      }
    });
  });
}
