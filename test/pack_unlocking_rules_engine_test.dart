import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/v2/unlock_rules.dart';
import 'package:poker_analyzer/services/pack_unlocking_rules_engine.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackUnlockingRulesEngine.instance
      ..mock = true
      ..devOverride = false
      ..resetMock();
  });

  test('locked when required pack not completed', () async {
    final tpl = TrainingPackTemplateV2(
      id: 'b',
      name: 'B',
      trainingType: TrainingType.pushFold,
      unlockRules: const UnlockRules(requiredPacks: ['a']),
    );
    final unlocked = await PackUnlockingRulesEngine.instance.isUnlocked(tpl);
    expect(unlocked, isFalse);
  });

  test('unlocked when requirements met', () async {
    final tpl = TrainingPackTemplateV2(
      id: 'b',
      name: 'B',
      trainingType: TrainingType.pushFold,
      unlockRules: const UnlockRules(requiredPacks: ['a'], minEV: 1),
    );
    PackUnlockingRulesEngine.instance
      ..markMockCompleted('a')
      ..mockAverageEV = 1.5;
    final unlocked = await PackUnlockingRulesEngine.instance.isUnlocked(tpl);
    expect(unlocked, isTrue);
  });

  test('uses unlock hint when provided', () async {
    final tpl = TrainingPackTemplateV2(
      id: 'b',
      name: 'B',
      trainingType: TrainingType.pushFold,
      unlockRules: const UnlockRules(
        requiredPacks: ['a'],
        unlockHint: 'Complete pack A first',
      ),
    );
    final unlocked = await PackUnlockingRulesEngine.instance.isUnlocked(tpl);
    expect(unlocked, isFalse);
    expect(
      PackUnlockingRulesEngine.instance.getUnlockRule(tpl)?.unlockHint,
      'Complete pack A first',
    );
  });

  test('dev override unlocks in debug mode', () async {
    final tpl = TrainingPackTemplateV2(
      id: 'b',
      name: 'B',
      trainingType: TrainingType.pushFold,
      unlockRules: const UnlockRules(requiredPacks: ['a']),
    );
    PackUnlockingRulesEngine.instance.devOverride = true;
    final unlocked = await PackUnlockingRulesEngine.instance.isUnlocked(tpl);
    expect(unlocked, isTrue);
  });
}
