// Pure Dart tests (no Flutter imports)

import 'package:test/test.dart';

import 'package:poker_analyzer/live/live_integration.dart';
import 'package:poker_analyzer/live/live_defaults.dart';

void main() {
  group('evaluateLiveProceduresForModule', () {
    test('Online mode returns null for any inputs', () {
      final v = evaluateLiveProceduresForModule(
        moduleId: 'live_etiquette_and_procedures',
        mode: TrainingMode.online,
        announced: false,
        chipMotions: 3,
        singleMotion: false,
        bettorWasAggressor: true,
        bettorShowedFirst: false,
        headsUp: false,
        firstActiveLeftOfBtnShowed: false,
      );
      expect(v, isNull);
      expect(
        liveWarningIfAny(
          moduleId: 'live_etiquette_and_procedures',
          mode: TrainingMode.online,
          announced: false,
          chipMotions: 3,
          singleMotion: false,
          bettorWasAggressor: true,
          bettorShowedFirst: false,
          headsUp: false,
          firstActiveLeftOfBtnShowed: false,
        ),
        equals(''),
      );
    });

    test(
      'Live + etiquette: string-bet triple condition fails with correct code and message',
      () {
        final v = evaluateLiveProceduresForModule(
          moduleId: 'live_etiquette_and_procedures',
          mode: TrainingMode.live,
          announced: false, // not announced
          chipMotions: 2, // multiple motions
          singleMotion: false, // would also fail, but string bet first
          bettorWasAggressor: true,
          bettorShowedFirst: false,
          headsUp: false,
          firstActiveLeftOfBtnShowed: false,
        );
        expect(v, isNotNull);
        expect(v!.code, equals('string_bet_call_only'));
        expect(
          liveWarningIfAny(
            moduleId: 'live_etiquette_and_procedures',
            mode: TrainingMode.live,
            announced: false,
            chipMotions: 2,
            singleMotion: false,
            bettorWasAggressor: true,
            bettorShowedFirst: false,
            headsUp: false,
            firstActiveLeftOfBtnShowed: false,
          ),
          equals(
            'Multiple chip motions without a spoken bet = string bet. Call only.',
          ),
        );
      },
    );

    test(
      'Live + full ring: compliant inputs pass; defaults alone do not violate',
      () {
        // This module has non-empty defaults (multiLimpers: 2, tableSpeed: slow) but
        // announceRequired is false, so string bet / single motion do not trigger by default.
        final v = evaluateLiveProceduresForModule(
          moduleId: 'live_full_ring_adjustments',
          mode: TrainingMode.live,
          announced: true,
          chipMotions: 1,
          singleMotion: true,
          bettorWasAggressor: false,
          bettorShowedFirst: false,
          headsUp: true,
          firstActiveLeftOfBtnShowed: true,
        );
        expect(v, isNull);
        expect(
          liveWarningIfAny(
            moduleId: 'live_full_ring_adjustments',
            mode: TrainingMode.live,
            announced: true,
            chipMotions: 1,
            singleMotion: true,
            bettorWasAggressor: false,
            bettorShowedFirst: false,
            headsUp: true,
            firstActiveLeftOfBtnShowed: true,
          ),
          equals(''),
        );
      },
    );

    test('Ordering matches LiveRuntime.firstViolation', () {
      // With multiple failures, string bet should be first for etiquette module.
      var v = evaluateLiveProceduresForModule(
        moduleId: 'live_etiquette_and_procedures',
        mode: TrainingMode.live,
        announced: false,
        chipMotions: 3,
        singleMotion: false,
        bettorWasAggressor: true,
        bettorShowedFirst: false,
        headsUp: false,
        firstActiveLeftOfBtnShowed: false,
      );
      expect(v, isNotNull);
      expect(v!.code, equals('string_bet_call_only'));

      // If we fix announce (string bet passes) but keep singleMotion false, the next should be single motion.
      v = evaluateLiveProceduresForModule(
        moduleId: 'live_etiquette_and_procedures',
        mode: TrainingMode.live,
        announced: true,
        chipMotions: 2,
        singleMotion: false,
        bettorWasAggressor: true,
        bettorShowedFirst: false,
        headsUp: true,
        firstActiveLeftOfBtnShowed: false,
      );
      expect(v, isNotNull);
      expect(v!.code, equals('single_motion_raise_required'));
    });
  });
}
