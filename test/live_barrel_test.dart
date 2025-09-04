// ASCII-only; pure Dart test (no Flutter imports)

import 'package:test/test.dart';
import 'package:poker_analyzer/live/live.dart';

void main() {
  group('live.dart barrel exports', () {
    test('symbols are reachable and behave as expected', () {
      // LiveRuntime.mode is not null
      expect(LiveRuntime.mode, isNotNull);

      // liveMessageFor(null) == ''
      expect(liveMessageFor(null), equals(''));

      // kLiveModuleIds.isNotEmpty
      expect(kLiveModuleIds.isNotEmpty, isTrue);

      // liveContextSubtitle(LiveContext.off()) == ''
      expect(liveContextSubtitle(const LiveContext.off()), equals(''));

      // livePrimaryAction('cash_rake_and_stakes', TrainingMode.live)
      expect(
        livePrimaryAction('cash_rake_and_stakes', TrainingMode.live),
        equals('Start Live practice'),
      );

      // evaluateLiveProceduresForModule(...) returns null for TrainingMode.online
      final v = evaluateLiveProceduresForModule(
        moduleId: 'live_tells_and_dynamics',
        mode: TrainingMode.online,
        announced: false,
        chipMotions: 2,
        singleMotion: false,
        bettorWasAggressor: true,
        bettorShowedFirst: false,
        headsUp: false,
        firstActiveLeftOfBtnShowed: false,
      );
      expect(v, isNull);
    });
  });
}
