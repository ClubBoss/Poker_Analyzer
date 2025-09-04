import 'package:test/test.dart';
import 'package:poker_analyzer/live/live.dart';
import 'package:poker_analyzer/live/live_event_adapter.dart';

void main() {
  group('processLiveAction', () {
    test('Online mode yields no warning and no telemetry', () {
      LiveRuntime.setMode(TrainingMode.online);
      final out = processLiveAction(
        moduleId: 'live_etiquette_and_procedures',
        mode: TrainingMode.online,
        announced: false,
        chipMotions: 3,
        singleMotion: false,
        bettorWasAggressor: false,
        bettorShowedFirst: false,
        headsUp: true,
        firstActiveLeftOfBtnShowed: true,
      );
      expect(out.warning, equals(''));
      expect(out.telemetryProps, isNull);
    });

    test(
      'Live mode string-bet violation returns message and telemetry props',
      () {
        LiveRuntime.setMode(TrainingMode.live);
        final id = 'live_etiquette_and_procedures';
        final out = processLiveAction(
          moduleId: id,
          mode: TrainingMode.live,
          announced: false, // no announce
          chipMotions: 2, // multiple motions -> string bet
          singleMotion: true,
          bettorWasAggressor: false,
          bettorShowedFirst: true,
          headsUp: true,
          firstActiveLeftOfBtnShowed: true,
        );
        expect(
          out.warning,
          equals(
            'Multiple chip motions without a spoken bet = string bet. Call only.',
          ),
        );
        expect(out.telemetryProps, isNotNull);
        expect(out.telemetryProps!['moduleId'], equals(id));
        expect(out.telemetryProps!['code'], equals('string_bet_call_only'));
        expect(out.telemetryProps!['mode'], equals('live'));
      },
    );

    test('Live mode compliant inputs yield no violation', () {
      LiveRuntime.setMode(TrainingMode.live);
      final out = processLiveAction(
        moduleId: 'live_etiquette_and_procedures',
        mode: TrainingMode.live,
        announced: false,
        chipMotions: 1, // single chip motion -> ok
        singleMotion: true,
        bettorWasAggressor: false, // not last aggressor -> ok
        bettorShowedFirst: false,
        headsUp: true, // heads-up -> firstActiveLeftOfBtnShowed irrelevant
        firstActiveLeftOfBtnShowed: false,
      );
      expect(out.warning, equals(''));
      expect(out.telemetryProps, isNull);
    });
  });
}
