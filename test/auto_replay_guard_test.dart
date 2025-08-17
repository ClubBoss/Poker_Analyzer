import 'package:test/test.dart';
import '../lib/ui/session_player/spot_specs.dart';
import '../lib/ui/session_player/models.dart';

void main() {
  test('canonical auto replay guard', () {
    const kinds = [
      SpotKind.l3_flop_jam_vs_raise,
      SpotKind.l3_turn_jam_vs_raise,
      SpotKind.l3_river_jam_vs_raise,
    ];

    for (final k in kinds) {
      expect(
        shouldAutoReplay(
          correct: false,
          autoWhy: true,
          kind: k,
          alreadyReplayed: false,
        ),
        isTrue,
      );
      expect(
        shouldAutoReplay(
          correct: true,
          autoWhy: true,
          kind: k,
          alreadyReplayed: false,
        ),
        isFalse,
      );
      expect(
        shouldAutoReplay(
          correct: false,
          autoWhy: false,
          kind: k,
          alreadyReplayed: false,
        ),
        isFalse,
      );
      expect(
        shouldAutoReplay(
          correct: false,
          autoWhy: true,
          kind: k,
          alreadyReplayed: true,
        ),
        isFalse,
      );
    }

    final nonL3 = SpotKind.values.firstWhere(
      (k) => !kinds.contains(k),
    );
    expect(
      shouldAutoReplay(
        correct: false,
        autoWhy: true,
        kind: nonL3,
        alreadyReplayed: false,
      ),
      isFalse,
    );
  });
}
