// ASCII-only; pure Dart test (no Flutter imports)

import 'package:test/test.dart';
import 'package:poker_analyzer/live/live_defaults.dart';
import 'package:poker_analyzer/live/live_ids.dart';

void main() {
  group('kLiveModuleIds / kLiveModuleIdSet', () {
    test('no duplicates and sizes match', () {
      final ids = kLiveModuleIds;
      final setFromList = ids.toSet();

      expect(ids.length, equals(kLiveModuleIdSet.length));
      expect(
        setFromList.length,
        equals(ids.length),
        reason: 'duplicates found',
      );
      expect(setFromList, equals(kLiveModuleIdSet));
    });

    test('keys in kLiveDefaults match kLiveModuleIdSet', () {
      expect(kLiveDefaults.keys.toSet(), equals(kLiveModuleIdSet));
    });

    test('order is stable and canonical', () {
      const expected = <String>[
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
      ];

      expect(kLiveModuleIds, equals(expected));
    });
  });
}
