// ASCII-only; pure Dart test (no Flutter imports)

import 'package:test/test.dart';
import 'package:poker_analyzer/live/live_defaults.dart';

void main() {
  group('kLiveDefaults', () {
    test('contains exactly the expected 11 live_* IDs', () {
      const expected = <String>{
        'live_tells_and_dynamics',
        'live_etiquette_and_procedures',
        'live_full_ring_adjustments',
        'live_special_formats_straddle_bomb_ante',
        'live_table_selection_and_seat_change',
        'live_chip_handling_and_bet_declares',
        'live_speech_timing_basics',
        'live_rake_structures_and_tips',
        'live_floor_calls_and_dispute_resolution',
        'live_session_log_and_review',
        'live_security_and_game_integrity',
      };

      expect(kLiveDefaults.keys.toSet(), equals(expected));
      expect(kLiveDefaults.length, 11);
    });
  });

  group('defaultLiveContextFor - Online mode', () {
    test(
      'returns LiveContext.off() for sample ids (live_*, cash_*, mtt_*)',
      () {
        const off = LiveContext.off();
        final samples = <String>[
          'live_tells_and_dynamics',
          'live_full_ring_adjustments',
          'cash_rake_and_stakes',
          'cash_blind_vs_blind',
          'mtt_short_stack',
          'mtt_day2_bagging',
        ];

        for (final id in samples) {
          final ctx = defaultLiveContextFor(
            mode: TrainingMode.online,
            moduleId: id,
          );
          expect(ctx, equals(off), reason: 'Online mode should be OFF for $id');
        }
      },
    );
  });

  group('defaultLiveContextFor - Live mode', () {
    test(
      'each live_* id returns context equal to kLiveDefaults[id] and invariants hold',
      () {
        for (final entry in kLiveDefaults.entries) {
          final id = entry.key;
          final expected = entry.value;
          final actual = defaultLiveContextFor(
            mode: TrainingMode.live,
            moduleId: id,
          );

          expect(actual, equals(expected), reason: 'Mismatch for $id');

          // Invariants
          expect(actual.multiLimpers, inInclusiveRange(0, 9));
          expect(actual.avgStackBb, greaterThanOrEqualTo(0));
          expect(<String>{'', 'time', 'drop'}, contains(actual.rakeType));
          expect(<String>{
            '',
            'slow',
            'normal',
            'fast',
          }, contains(actual.tableSpeed));
        }
      },
    );

    test(
      'cash_rake_and_stakes and mtt_short_stack return LiveContext.off()',
      () {
        const off = LiveContext.off();
        final cashCtx = defaultLiveContextFor(
          mode: TrainingMode.live,
          moduleId: 'cash_rake_and_stakes',
        );
        final mttCtx = defaultLiveContextFor(
          mode: TrainingMode.live,
          moduleId: 'mtt_short_stack',
        );

        expect(cashCtx, equals(off));
        expect(mttCtx, equals(off));
      },
    );
  });
}
