import 'package:test/test.dart';

import '../lib/ui/session_player/models.dart';
import '../lib/ui/session_player/spot_specs.dart';

void main() {
  test('L3 jam_vs_raise kinds are jam/fold & auto-replay', () {
    const kinds = [
      SpotKind.l3_flop_jam_vs_raise,
      SpotKind.l3_turn_jam_vs_raise,
      SpotKind.l3_river_jam_vs_raise,
    ];
    for (final k in kinds) {
      expect(isJamFold(k), isTrue);
      expect(isAutoReplayKind(k), isTrue);
    }
  });

  test('Non-L3 kind is not auto-replay', () {
    final nonL3 = SpotKind.values.firstWhere(
      (k) =>
          k != SpotKind.l3_flop_jam_vs_raise &&
          k != SpotKind.l3_turn_jam_vs_raise &&
          k != SpotKind.l3_river_jam_vs_raise,
    );
    expect(isAutoReplayKind(nonL3), isFalse);
  });
}
