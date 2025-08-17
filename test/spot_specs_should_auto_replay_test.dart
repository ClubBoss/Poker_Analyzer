import 'package:test/test.dart';
import '../lib/ui/session_player/spot_specs.dart';
import '../lib/ui/session_player/models.dart';

void main() {
  group('shouldAutoReplay', () {
    final l3 = [
      SpotKind.l3_flop_jam_vs_raise,
      SpotKind.l3_turn_jam_vs_raise,
      SpotKind.l3_river_jam_vs_raise,
    ];
    final l4 = [
      SpotKind.l4_icm_bubble_jam_vs_fold,
      SpotKind.l4_icm_ladder_jam_vs_fold,
      SpotKind.l4_icm_sb_jam_vs_fold,
    ];

    test('fires only when all conditions are met (L3 kinds)', () {
      for (final k in l3) {
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
    });

    test('never fires for non-L3 kinds even with other flags true', () {
      for (final k in l4) {
        expect(
          shouldAutoReplay(
            correct: false,
            autoWhy: true,
            kind: k,
            alreadyReplayed: false,
          ),
          isFalse,
        );
      }
    });

    test('helper parity with canonical guard set', () {
      for (final k in SpotKind.values) {
        final expected = isAutoReplayKind(k);
        // Only correct=false, autoWhy=true, not yet replayed should yield expected.
        expect(
          shouldAutoReplay(
            correct: false,
            autoWhy: true,
            kind: k,
            alreadyReplayed: false,
          ),
          expected,
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
    });
  });
}
