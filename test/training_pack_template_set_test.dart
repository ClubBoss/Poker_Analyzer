import 'package:test/test.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_set.dart';

void main() {
  test('generateAllPacks expands variants', () {
    const yaml = '''
templateSet:
  id: set1
  name: Streets
  baseTemplate:
    id: base
    name: Base
    trainingType: pushFold
    spots: []
    spotCount: 0
  dynamicParamVariants:
    - id: pack-flop
      name: BTN vs BB Flop
      targetStreet: flop
      count: 0
    - id: pack-turn
      name: BTN vs BB Turn
      targetStreet: turn
      count: 0
''';

    final packs = TrainingPackTemplateSet.generateAllFromYaml(yaml);
    expect(packs.length, 2);
    expect(packs[0].id, 'pack-flop');
    expect(packs[0].name, 'BTN vs BB Flop');
    expect(packs[0].meta['dynamicParams']['targetStreet'], 'flop');
    expect(packs[1].id, 'pack-turn');
    expect(packs[1].meta['dynamicParams']['targetStreet'], 'turn');
  });
}
