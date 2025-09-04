// Pure Dart tests (no Flutter imports)

import 'package:test/test.dart';

import 'package:poker_analyzer/live/live_actions.dart';
import 'package:poker_analyzer/live/live_mode.dart';

void main() {
  group('livePrimaryAction', () {
    test('live_tells_and_dynamics → Start Live practice in both modes', () {
      expect(
        livePrimaryAction('live_tells_and_dynamics', TrainingMode.online),
        equals('Start Live practice'),
      );
      expect(
        livePrimaryAction('live_tells_and_dynamics', TrainingMode.live),
        equals('Start Live practice'),
      );
    });

    test('cash_rake_and_stakes → null online; Start Live practice in live', () {
      expect(
        livePrimaryAction('cash_rake_and_stakes', TrainingMode.online),
        isNull,
      );
      expect(
        livePrimaryAction('cash_rake_and_stakes', TrainingMode.live),
        equals('Start Live practice'),
      );
    });

    test('mtt_short_stack → null online; Start Live practice in live', () {
      expect(livePrimaryAction('mtt_short_stack', TrainingMode.online), isNull);
      expect(
        livePrimaryAction('mtt_short_stack', TrainingMode.live),
        equals('Start Live practice'),
      );
    });

    test('math_ev_calculations → null in both modes', () {
      expect(
        livePrimaryAction('math_ev_calculations', TrainingMode.online),
        isNull,
      );
      expect(
        livePrimaryAction('math_ev_calculations', TrainingMode.live),
        isNull,
      );
    });
  });
}
