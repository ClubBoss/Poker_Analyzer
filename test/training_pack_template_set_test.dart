import 'package:test/test.dart';
import 'package:poker_analyzer/services/training_pack_template_set_generator.dart';

void main() {
  test('generate expands variants', () {
    const yaml = '''
template:
  id: gen_pack
  trainingType: pushFold
  spots: []
  spotCount: 0
  meta:
    dynamicParams:
      villainAction: "{{action}}"
      targetStreet: "{{street}}"
variants:
  - action: "3bet 9.0"
    street: flop
  - action: "3bet 7.5"
    street: turn
''';

    final packs = const TrainingPackTemplateSetGenerator().generateFromYaml(
      yaml,
    );
    expect(packs.length, 2);
    expect(packs[0].meta['dynamicParams']['villainAction'], '3bet 9.0');
    expect(packs[0].meta['dynamicParams']['targetStreet'], 'flop');
    expect(packs[1].meta['dynamicParams']['villainAction'], '3bet 7.5');
    expect(packs[1].meta['dynamicParams']['targetStreet'], 'turn');
  });
}
