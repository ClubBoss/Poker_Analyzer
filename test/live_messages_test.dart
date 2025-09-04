// Pure Dart tests for live_messages

import 'package:test/test.dart';

import 'package:poker_analyzer/live/live_messages.dart';
import 'package:poker_analyzer/live/live_validators.dart';

void main() {
  group('liveMessageForCode', () {
    test('returns exact strings for known codes', () {
      expect(
        liveMessageForCode('string_bet_call_only'),
        equals(
          'Multiple chip motions without a spoken bet = string bet. Call only.',
        ),
      );
      expect(
        liveMessageForCode('single_motion_raise_required'),
        equals('Raises must be a single motion or clearly announced.'),
      );
      expect(
        liveMessageForCode('bettor_shows_first_required'),
        equals('Aggressor shows first at showdown.'),
      );
      expect(
        liveMessageForCode('first_active_left_of_btn_shows_required'),
        equals(
          'In multiway pots the first active player left of the button shows first.',
        ),
      );
    });

    test('returns generic for unknown code', () {
      expect(
        liveMessageForCode('unknown_code_xyz'),
        equals('Live procedure violation.'),
      );
    });
  });

  group('liveMessageFor', () {
    test('null returns empty string', () {
      expect(liveMessageFor(null), equals(''));
    });

    test('maps LiveViolation codes via liveMessageForCode', () {
      const v = LiveViolation('bettor_shows_first_required', 'X');
      expect(liveMessageFor(v), equals('Aggressor shows first at showdown.'));
    });
  });

  group('stability', () {
    test('keys set matches codes used by live_validators.dart', () {
      // Keep these in sync with lib/live/live_validators.dart
      const expectedCodes = <String>{
        'string_bet_call_only',
        'single_motion_raise_required',
        'bettor_shows_first_required',
        'first_active_left_of_btn_shows_required',
      };

      expect(kLiveViolationMessages.keys.toSet(), equals(expectedCodes));
    });
  });
}
