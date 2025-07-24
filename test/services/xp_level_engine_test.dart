import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/xp_level_engine.dart';

void main() {
  group('XPLevelEngine', () {
    final engine = XPLevelEngine.instance;

    test('computes correct levels', () {
      expect(engine.getLevel(0), 1);
      expect(engine.getLevel(99), 1);
      expect(engine.getLevel(100), 2);
      expect(engine.getLevel(399), 2);
      expect(engine.getLevel(400), 3);
    });

    test('computes progress to next level', () {
      expect(engine.getProgressToNextLevel(0), 0.0);
      expect(engine.getProgressToNextLevel(50), closeTo(0.5, 0.001));
      expect(engine.getProgressToNextLevel(100), 0.0);
      final pct = (250 - 100) / (400 - 100);
      expect(engine.getProgressToNextLevel(250), closeTo(pct, 0.001));
    });
  });
}
