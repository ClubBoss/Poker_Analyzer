import 'package:test/test.dart';
import 'package:poker_analyzer/ui/modules/icm_ladder_packs.dart';
import 'package:poker_analyzer/ui/session_player/models.dart';
import 'package:poker_analyzer/ui/session_player/spot_specs.dart';

void main() {
  test('ICM L4 Ladder pack loads and has jam/fold wiring', () {
    final spots = loadIcmL4LadderV1();
    expect(spots, isNotEmpty);
    expect(spots.map((s) => s.kind).toSet(), {
      SpotKind.l4_icm_ladder_jam_vs_fold,
    });
    expect(actionsMap[SpotKind.l4_icm_ladder_jam_vs_fold], ['jam', 'fold']);
    expect(
      subtitlePrefix[SpotKind.l4_icm_ladder_jam_vs_fold],
      'ICM FT Ladder Jam vs Fold • ',
    );
  });
}
