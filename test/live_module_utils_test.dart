import 'package:test/test.dart';
import 'package:poker_analyzer/live/live_module_utils.dart';

void main() {
  group('live_module_utils', () {
    test('isLiveModuleId basics', () {
      expect(isLiveModuleId('live_tells_and_dynamics'), isTrue);

      // Should be false for non-live prefixes
      expect(isLiveModuleId('cash_rake_and_stakes'), isFalse);
      expect(isLiveModuleId('mtt_short_stack'), isFalse);
      expect(isLiveModuleId('math_probabilities_overview'), isFalse);
    });

    test('isPracticeModuleId basics', () {
      expect(isPracticeModuleId('cash_rake_and_stakes'), isTrue);
      expect(isPracticeModuleId('mtt_short_stack'), isTrue);

      // Should be false for live and unrelated prefixes
      expect(isPracticeModuleId('live_tells_and_dynamics'), isFalse);
      expect(isPracticeModuleId('math_probabilities_overview'), isFalse);
    });

    test('boundary: empty and unrelated', () {
      expect(isLiveModuleId(''), isFalse);
      expect(isPracticeModuleId(''), isFalse);

      expect(isLiveModuleId('theory_intro'), isFalse);
      expect(isPracticeModuleId('theory_intro'), isFalse);
    });
  });
}
