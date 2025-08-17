import 'package:test/test.dart';

import '../lib/ui/session_player/models.dart';
import '../lib/ui/session_player/spot_specs.dart';

void main() {
  test('L4 ICM SB Jam vs Fold SSOT invariants', () {
    final k = SpotKind.l4_icm_sb_jam_vs_fold;
    expect(isJamFold(k), true);
    expect(isAutoReplayKind(k), false);
    expect(actionsMap[k], ['jam', 'fold']);
    expect(subtitlePrefix[k]!.startsWith('ICM SB Jam vs Fold • '), true);
  });
}
