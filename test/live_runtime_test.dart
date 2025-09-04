// Pure Dart tests (no Flutter imports)

import 'package:test/test.dart';

import 'package:poker_analyzer/live/live_runtime.dart';
import 'package:poker_analyzer/live/live_badges.dart';
import 'package:poker_analyzer/live/live_defaults.dart';
// Removed unused validators import

void main() {
  setUp(() {
    // Ensure a known starting mode for each test
    LiveRuntime.setMode(TrainingMode.online);
  });

  tearDown(() {
    // Reset to online to avoid cross-test state leakage
    LiveRuntime.setMode(TrainingMode.online);
  });

  group('badgesForModule mirrors liveBadgesForModule', () {
    test('online mode', () {
      LiveRuntime.setMode(TrainingMode.online);
      final ids = <String>[
        'live_tells_and_dynamics',
        'cash_threebet_pots',
        'mtt_icm_basics',
        'theory_random',
      ];
      for (final id in ids) {
        expect(
          LiveRuntime.badgesForModule(id),
          liveBadgesForModule(moduleId: id, mode: LiveRuntime.mode),
          reason: 'Mismatch for $id in online mode',
        );
      }
    });

    test('live mode', () {
      LiveRuntime.setMode(TrainingMode.live);
      final ids = <String>[
        'live_tells_and_dynamics',
        'cash_threebet_pots',
        'mtt_icm_basics',
        'theory_random',
      ];
      for (final id in ids) {
        expect(
          LiveRuntime.badgesForModule(id),
          liveBadgesForModule(moduleId: id, mode: LiveRuntime.mode),
          reason: 'Mismatch for $id in live mode',
        );
      }
    });
  });

  group('contextFor by mode', () {
    test('online mode returns LiveContext.off for live_* modules', () {
      LiveRuntime.setMode(TrainingMode.online);
      for (final id in kLiveDefaults.keys) {
        final ctx = LiveRuntime.contextFor(id);
        expect(
          ctx,
          equals(const LiveContext.off()),
          reason: 'Expected off for $id',
        );
      }
    });

    test('live mode returns kLiveDefaults for live_* modules', () {
      LiveRuntime.setMode(TrainingMode.live);
      for (final entry in kLiveDefaults.entries) {
        final ctx = LiveRuntime.contextFor(entry.key);
        expect(
          ctx,
          equals(entry.value),
          reason: 'Expected default for ${entry.key}',
        );
      }
    });
  });

  group('firstViolation and messageFor', () {
    test('compliant inputs return null and empty message', () {
      final ctx = const LiveContext(
        hasStraddle: false,
        bombAnte: false,
        multiLimpers: 0,
        announceRequired: false, // announce not required
        rakeType: '',
        avgStackBb: 0,
        tableSpeed: '',
      );

      final v = LiveRuntime.firstViolation(
        ctx: ctx,
        announced: false,
        chipMotions: 2,
        singleMotion: false,
        bettorWasAggressor: false,
        bettorShowedFirst: false,
        headsUp: true, // avoids multiway rule
        firstActiveLeftOfBtnShowed: false,
      );
      expect(v, isNull);
      expect(LiveRuntime.messageFor(v), equals(''));
    });

    test('first failure is string bet when applicable', () {
      final ctx = const LiveContext(
        hasStraddle: false,
        bombAnte: false,
        multiLimpers: 0,
        announceRequired: true,
        rakeType: '',
        avgStackBb: 0,
        tableSpeed: '',
      );

      final v = LiveRuntime.firstViolation(
        ctx: ctx,
        announced: false, // not announced
        chipMotions:
            2, // multiple motions triggers string bet under announceRequired
        singleMotion: false, // would also fail, but string bet should be first
        bettorWasAggressor: true,
        bettorShowedFirst: false,
        headsUp: false,
        firstActiveLeftOfBtnShowed: false,
      );

      expect(v, isNotNull);
      expect(v!.code, equals('string_bet_call_only'));
      expect(
        LiveRuntime.messageFor(v),
        equals(
          'Multiple chip motions without a spoken bet = string bet. Call only.',
        ),
      );
    });

    test('first failure is single motion raise when string bet passes', () {
      final ctx = const LiveContext(
        hasStraddle: false,
        bombAnte: false,
        multiLimpers: 0,
        announceRequired: true,
        rakeType: '',
        avgStackBb: 0,
        tableSpeed: '',
      );

      final v = LiveRuntime.firstViolation(
        ctx: ctx,
        announced: true, // announce passes string bet
        chipMotions: 2,
        singleMotion: false, // fails here
        bettorWasAggressor: true,
        bettorShowedFirst: false,
        headsUp: true,
        firstActiveLeftOfBtnShowed: false,
      );

      expect(v, isNotNull);
      expect(v!.code, equals('single_motion_raise_required'));
      expect(
        LiveRuntime.messageFor(v),
        equals('Raises must be a single motion or clearly announced.'),
      );
    });

    test('bettor shows first is next when prior pass', () {
      final ctx = const LiveContext(
        hasStraddle: false,
        bombAnte: false,
        multiLimpers: 0,
        announceRequired: true,
        rakeType: '',
        avgStackBb: 0,
        tableSpeed: '',
      );

      final v = LiveRuntime.firstViolation(
        ctx: ctx,
        announced: true, // pass string bet
        chipMotions: 1, // pass string bet
        singleMotion: true, // pass single motion
        bettorWasAggressor: true,
        bettorShowedFirst: false, // fail here
        headsUp: true, // avoid multiway rule
        firstActiveLeftOfBtnShowed: false,
      );

      expect(v, isNotNull);
      expect(v!.code, equals('bettor_shows_first_required'));
      expect(
        LiveRuntime.messageFor(v),
        equals('Aggressor shows first at showdown.'),
      );
    });

    test('multiway first active left of button shows is last', () {
      final ctx = const LiveContext(
        hasStraddle: false,
        bombAnte: false,
        multiLimpers: 0,
        announceRequired: true,
        rakeType: '',
        avgStackBb: 0,
        tableSpeed: '',
      );

      final v = LiveRuntime.firstViolation(
        ctx: ctx,
        announced: true, // pass string bet
        chipMotions: 1, // pass string bet
        singleMotion: true, // pass single motion
        bettorWasAggressor: false, // pass bettor shows first
        bettorShowedFirst: false,
        headsUp: false, // multiway triggers last rule
        firstActiveLeftOfBtnShowed: false, // fail here
      );

      expect(v, isNotNull);
      expect(v!.code, equals('first_active_left_of_btn_shows_required'));
      expect(
        LiveRuntime.messageFor(v),
        equals(
          'In multiway pots the first active player left of the button shows first.',
        ),
      );
    });
  });

  group('toggle integration', () {
    test('toggle affects badges and context', () {
      // Start in online
      LiveRuntime.setMode(TrainingMode.online);
      expect(LiveRuntime.isLive, isFalse);

      final cashId = 'cash_threebet_pots';
      final liveId = kLiveDefaults.keys.first;

      expect(LiveRuntime.badgesForModule(cashId), isEmpty);
      expect(LiveRuntime.contextFor(liveId), equals(const LiveContext.off()));

      // Toggle to live
      LiveRuntime.toggle();
      expect(LiveRuntime.isLive, isTrue);

      expect(LiveRuntime.badgesForModule(cashId), equals(const ['Live']));
      expect(LiveRuntime.contextFor(liveId), equals(kLiveDefaults[liveId]));
    });
  });
}
