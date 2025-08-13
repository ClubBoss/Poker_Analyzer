import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/skill_tree_motivational_hint_engine.dart';
import 'package:poker_analyzer/services/skill_tree_progress_analytics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  SkillTreeProgressStats stats({double rate = 1.0, int level = 1}) =>
      SkillTreeProgressStats(
        totalNodes: 1,
        completedNodes: rate == 1.0 ? 1 : 0,
        completionRate: rate,
        completionRateByLevel: {level: rate},
      );

  test('level completion message shown once per level', () async {
    final engine = SkillTreeMotivationalHintEngine(cooldown: Duration.zero);
    await engine.resetForTest();
    final msg1 = await engine.getMotivationalMessage(stats());
    expect(msg1, 'Level 1 complete!');
    final msg2 = await engine.getMotivationalMessage(stats());
    expect(msg2, isNull);
  });

  test('progress message triggered near completion', () async {
    final engine = SkillTreeMotivationalHintEngine(cooldown: Duration.zero);
    await engine.resetForTest();
    final msg = await engine.getMotivationalMessage(stats(rate: 0.8));
    expect(msg, 'Almost there!');
  });

  test('cooldown prevents repeated messages', () async {
    final engine =
        SkillTreeMotivationalHintEngine(cooldown: Duration(seconds: 5));
    await engine.resetForTest();
    final first = await engine.getMotivationalMessage(stats(rate: 0.8));
    expect(first, isNotNull);
    final second = await engine.getMotivationalMessage(stats(rate: 0.8));
    expect(second, isNull);
  });
}
