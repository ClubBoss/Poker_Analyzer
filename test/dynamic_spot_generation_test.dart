import 'package:test/test.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_v2.dart';

void main() {
  const yaml = '''
id: dyn_pack
name: Dynamic Pack
trainingType: mtt
bb: 100
positions:
  - utg
meta:
  schemaVersion: 2.0.0
dynamicSpots:
  - handPool:
      - Ad Qh
      - Ac Qd
      - Ah Qc
    villainAction: 3bet 9.0
    heroOptions: [call, fold]
    position: utg
    playerCount: 6
    stack: 100
    sampleSize: 2
''';

  test('dynamic pack generates random spots from hand pool', () {
    final tpl = TrainingPackTemplateV2.fromYamlAuto(yaml);
    expect(tpl.dynamicSpots.length, 1);
    final pack = TrainingPackV2.fromTemplate(tpl, 'p1');
    expect(pack.spots.length, 2);
    final pool = tpl.dynamicSpots.first.handPool;
    for (final s in pack.spots) {
      expect(pool.contains(s.hand.heroCards), true);
      expect(s.heroOptions, ['call', 'fold']);
    }
  });

  test('dynamicParams generate spots via generator service', () {
    const yaml2 = '''
id: gen_pack
name: Generator Pack
trainingType: mtt
positions:
  - hj
meta:
  dynamicParams:
    position: hj
    villainAction: "3bet 9.0"
    handGroup: ["pockets"]
    count: 3
''';
    final tpl = TrainingPackTemplateV2.fromYamlAuto(yaml2);
    expect(tpl.spots.length, 3);
    expect(tpl.spotCount, 3);
  });

  test('dynamicParams boardFilter generates ace high boards', () {
    const yaml3 = '''
id: gen_pack
name: Generator Pack
trainingType: mtt
positions:
  - hj
meta:
  dynamicParams:
    position: hj
    villainAction: "3bet 9.0"
    handGroup: ["pockets"]
    count: 3
    boardFilter:
      boardTexture: aceHigh
''';
    final tpl = TrainingPackTemplateV2.fromYamlAuto(yaml3);
    expect(tpl.spots.length, 3);
    for (final s in tpl.spots) {
      expect(s.board.any((c) => c.startsWith('A')), true);
    }
  });

  test('dynamicParams boardTextureTags generates ace high boards', () {
    const yamlTags = '''
id: gen_pack
name: Generator Pack
trainingType: mtt
positions:
  - hj
meta:
  dynamicParams:
    position: hj
    villainAction: "3bet 9.0"
    handGroup: ["pockets"]
    count: 3
    boardTextureTags: ['aceHigh']
''';
    final tpl = TrainingPackTemplateV2.fromYamlAuto(yamlTags);
    expect(tpl.spots.length, 3);
    for (final s in tpl.spots) {
      expect(s.board.any((c) => c.startsWith('A')), true);
    }
  });

  test('dynamicParams boardTextureTags highCard generates high card boards', () {
    const yamlHigh = '''
id: gen_pack
name: Generator Pack
trainingType: mtt
positions:
  - hj
meta:
  dynamicParams:
    position: hj
    villainAction: "3bet 9.0"
    handGroup: ["pockets"]
    count: 3
    boardTextureTags: ['highCard']
''';
    final tpl = TrainingPackTemplateV2.fromYamlAuto(yamlHigh);
    expect(tpl.spots.length, 3);
    for (final s in tpl.spots) {
      expect(s.board.any((c) => 'TJQKA'.contains(c[0])), true);
    }
  });

  test('boardFilter overrides boardTextureTags when conflicting', () {
    const yamlOverride = '''
id: gen_pack
name: Generator Pack
trainingType: mtt
positions:
  - hj
meta:
  dynamicParams:
    position: hj
    villainAction: "3bet 9.0"
    handGroup: ["pockets"]
    count: 3
    boardTextureTags: ['aceHigh']
    boardFilter:
      boardTexture: low
''';
    final tpl = TrainingPackTemplateV2.fromYamlAuto(yamlOverride);
    expect(tpl.spots.length, 3);
    for (final s in tpl.spots) {
      expect(s.board.any((c) => c.startsWith('A')), false);
    }
  });

  test('dynamicParams boardStages generates full boards', () {
    const yaml4 = '''
id: gen_pack
name: Generator Pack
trainingType: mtt
positions:
  - hj
meta:
  dynamicParams:
    position: hj
    villainAction: "3bet 9.0"
    handGroup: ["pockets"]
    count: 2
    boardStages: 5
''';
    final tpl = TrainingPackTemplateV2.fromYamlAuto(yaml4);
    expect(tpl.spots.length, 2);
    for (final s in tpl.spots) {
      expect(s.board.length, 5);
    }
  });
}
