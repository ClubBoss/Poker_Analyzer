import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/core/training/generation/smart_path_seed_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generateFromStringList builds stages with subStages and unlocks', () {
    const generator = SmartPathSeedGenerator();
    final stages = generator.generateFromStringList([
      'bb10_UTG:A,B,C',
      'bb10_CO:A,B',
    ]);
    expect(stages.length, 2);

    final s1 = stages.first;
    expect(s1.id, 'bb10_UTG');
    expect(s1.packId, 'bb10_UTG_main');
    expect(s1.subStages.length, 3);
    expect(s1.subStages.first.id, 'bb10_UTG_A');
    expect(s1.subStages[1].unlockCondition?.dependsOn, 'bb10_UTG_A');

    final s2 = stages[1];
    expect(s2.unlockCondition?.dependsOn, 'bb10_UTG');
    expect(s2.subStages.first.id, 'bb10_CO_A');
  });
}
