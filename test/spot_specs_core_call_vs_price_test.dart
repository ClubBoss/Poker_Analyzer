import 'package:test/test.dart';

import '../lib/ui/session_player/spot_specs.dart';
import '../lib/ui/session_player/models.dart';

void main() {
  group('L1 core call vs price SSOT', () {
    test('enum append-only', () {
      expect(SpotKind.values.last, SpotKind.l1_core_call_vs_price);
    });

    test('actions mapping', () {
      expect(actionsMap[SpotKind.l1_core_call_vs_price], ['call', 'fold']);
    });

    test('subtitle prefix', () {
      expect(
        subtitlePrefix[SpotKind.l1_core_call_vs_price],
        startsWith('Pot Odds \u2022 '),
      );
    });

    test('not jam/fold', () {
      expect(isJamFold(SpotKind.l1_core_call_vs_price), isFalse);
    });

    test('no auto-replay', () {
      expect(
        shouldAutoReplay(
          correct: false,
          autoWhy: true,
          kind: SpotKind.l1_core_call_vs_price,
          alreadyReplayed: false,
        ),
        isFalse,
      );
    });
  });
}
