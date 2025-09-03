// Pure Dart tests for live_validators

import 'package:test/test.dart';

import 'package:poker_analyzer/live/live_context.dart';
import 'package:poker_analyzer/live/live_validators.dart';

void main() {
  group(
    'LiveViolation basics',
    () => {
      test('equality and hashCode', () {
        const a = LiveViolation('code_a', 'Message A');
        const b = LiveViolation('code_a', 'Message A');
        const c = LiveViolation('code_b', 'Message A');
        const d = LiveViolation('code_a', 'Message B');

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
        expect(a == c, isFalse);
        expect(a == d, isFalse);
      }),
      test('toString is stable and readable', () {
        const v = LiveViolation('string_bet_call_only', 'X');
        expect(
          v.toString(),
          equals('LiveViolation(code: string_bet_call_only, message: X)'),
        );
      }),
    },
  );

  group('checkStringBet', () {
    test('fails only when announceRequired && chipMotions>1 && !announced', () {
      final ctx = const LiveContext(
        hasStraddle: false,
        bombAnte: false,
        multiLimpers: 0,
        announceRequired: true,
        rakeType: '',
        avgStackBb: 100,
        tableSpeed: 'normal',
      );

      // Fail case
      final v1 = checkStringBet(ctx: ctx, announced: false, chipMotions: 2);
      expect(v1, isNotNull);
      expect(v1!.code, 'string_bet_call_only');

      // Pass cases: any of the conditions not met
      expect(checkStringBet(ctx: ctx, announced: true, chipMotions: 2), isNull);
      expect(
        checkStringBet(ctx: ctx, announced: false, chipMotions: 1),
        isNull,
      );
      expect(
        checkStringBet(
          ctx: ctx.copyWith(announceRequired: false),
          announced: false,
          chipMotions: 3,
        ),
        isNull,
      );
    });

    test('no-op when overlay is off (LiveContext.off)', () {
      final ctx = const LiveContext.off();
      expect(
        checkStringBet(ctx: ctx, announced: false, chipMotions: 10),
        isNull,
      );
    });
  });

  group('checkSingleMotionRaise', () {
    test('fails when announceRequired && !singleMotion', () {
      final ctx = const LiveContext(
        hasStraddle: false,
        bombAnte: false,
        multiLimpers: 0,
        announceRequired: true,
        rakeType: '',
        avgStackBb: 100,
        tableSpeed: 'normal',
      );
      final v = checkSingleMotionRaise(ctx: ctx, singleMotion: false);
      expect(v, isNotNull);
      expect(v!.code, 'single_motion_raise_required');

      // Pass when single motion or announce not required
      expect(checkSingleMotionRaise(ctx: ctx, singleMotion: true), isNull);
      expect(
        checkSingleMotionRaise(
          ctx: ctx.copyWith(announceRequired: false),
          singleMotion: false,
        ),
        isNull,
      );
    });

    test('no-op when overlay is off (LiveContext.off)', () {
      final ctx = const LiveContext.off();
      expect(checkSingleMotionRaise(ctx: ctx, singleMotion: false), isNull);
    });
  });

  group('checkBettorShowsFirst', () {
    test('fails when bettorWasAggressor && !bettorShowedFirst', () {
      final ctx = const LiveContext.off(); // ctx not used for logic here
      final v = checkBettorShowsFirst(
        ctx: ctx,
        bettorWasAggressor: true,
        bettorShowedFirst: false,
      );
      expect(v, isNotNull);
      expect(v!.code, 'bettor_shows_first_required');
    });

    test('passes otherwise', () {
      final ctx = const LiveContext.off();
      expect(
        checkBettorShowsFirst(
          ctx: ctx,
          bettorWasAggressor: true,
          bettorShowedFirst: true,
        ),
        isNull,
      );
      expect(
        checkBettorShowsFirst(
          ctx: ctx,
          bettorWasAggressor: false,
          bettorShowedFirst: false,
        ),
        isNull,
      );
    });
  });

  group('checkFirstActiveLeftOfBtnShows', () {
    test('fails when !headsUp && !firstActiveLeftOfBtnShowed', () {
      final ctx = const LiveContext.off(); // ctx not used for logic here
      final v = checkFirstActiveLeftOfBtnShows(
        ctx: ctx,
        headsUp: false,
        firstActiveLeftOfBtnShowed: false,
      );
      expect(v, isNotNull);
      expect(v!.code, 'first_active_left_of_btn_shows_required');
    });

    test('passes otherwise', () {
      final ctx = const LiveContext.off();
      expect(
        checkFirstActiveLeftOfBtnShows(
          ctx: ctx,
          headsUp: true,
          firstActiveLeftOfBtnShowed: false,
        ),
        isNull,
      );
      expect(
        checkFirstActiveLeftOfBtnShows(
          ctx: ctx,
          headsUp: false,
          firstActiveLeftOfBtnShowed: true,
        ),
        isNull,
      );
    });
  });
}
