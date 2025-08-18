import 'package:test/test.dart';
import 'package:poker_analyzer/ui/modules/icm_mix_packs.dart';
import 'package:poker_analyzer/ui/session_player/models.dart';
import 'package:poker_analyzer/ui/session_player/spot_specs.dart';

void main() {
  test('ICM Mix pack loads and has jam/fold wiring', () {
    final spots = loadIcmL4MixV1();
    expect(spots.isNotEmpty, true);
    final kinds = spots.map((s) => s.kind).toSet();
    expect(
      kinds
          .difference({
            SpotKind.l4_icm_sb_jam_vs_fold,
            SpotKind.l4_icm_bb_jam_vs_fold,
          })
          .isEmpty,
      true,
    );
    for (final k in kinds) {
      expect(actionsMap[k], ['jam', 'fold']);
      final prefix = k == SpotKind.l4_icm_sb_jam_vs_fold
          ? 'ICM SB Jam vs Fold \u2022 '
          : 'ICM BB Jam vs Fold \u2022 ';
      expect(subtitlePrefix[k], prefix);
    }
  });

  test('ICM Mix pack has no duplicate jam keys', () {
    final spots = loadIcmL4MixV1();
    final keys = spots.map(jamDedupKey).toList();
    expect(keys.toSet().length, keys.length);
  });
}
