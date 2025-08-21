import 'package:test/test.dart';
import 'package:poker_analyzer/ui/session_player/models.dart';
import 'package:poker_analyzer/ui/session_player/spot_specs.dart';

UiAnswer ok(int ms) => UiAnswer(
      correct: true,
      expected: 'jam',
      chosen: 'jam',
      elapsed: Duration(milliseconds: ms),
    );
UiAnswer ng(int ms) => UiAnswer(
      correct: false,
      expected: 'jam',
      chosen: 'fold',
      elapsed: Duration(milliseconds: ms),
    );

void main() {
  group('LadderOutcome SSOT', () {
    test('passes at thresholds (80% acc, <=1800 ms avg)', () {
      final ans = [
        ok(1500),
        ok(1500),
        ok(1500),
        ok(1500),
        ng(1500),
      ]; // 4/5 = 80%, avg 1500
      final o = computeLadderOutcome(ans);
      expect(o.total, 5);
      expect(o.accPct, 80.0);
      expect(o.avgMs, 1500);
      expect(o.passed, true);
    });

    test('fails by accuracy (<80%)', () {
      final ans = [
        ok(1200),
        ok(1200),
        ok(1200),
        ng(1200),
        ng(1200),
      ]; // 3/5 = 60%
      final o = computeLadderOutcome(ans);
      expect(o.passed, false);
    });

    test('fails by speed (>1800 ms)', () {
      final ans = [
        ok(2000),
        ok(2000),
        ok(2000),
        ok(2000),
        ng(2000),
      ]; // 80% but 2000 ms
      final o = computeLadderOutcome(ans);
      expect(o.passed, false);
    });

    test('empty session is not a pass', () {
      final o = computeLadderOutcome(const []);
      expect(o.total, 0);
      expect(o.passed, false);
    });
  });
}
