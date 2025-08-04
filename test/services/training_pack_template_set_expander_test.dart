import 'package:test/test.dart';
import 'package:poker_analyzer/services/training_pack_template_set_expander.dart';

void main() {
  test('expander filters spots and sets origin', () {
    const yaml = '''
id: base_pack
name: Base Pack
trainingType: mtt
positions: [btn]
spots:
  - id: s1
    hand:
      heroCards: Ah Kh
      position: btn
      heroIndex: 0
      playerCount: 2
      board: []
    board: []
    villainAction: check
  - id: s2
    hand:
      heroCards: Qh Qd
      position: btn
      heroIndex: 0
      playerCount: 2
      board: [2h, 2c, 9d]
    board: [2h, 2c, 9d]
    villainAction: bet
spotCount: 2
templateSet:
  - name: Paired Boards
    constraints:
      boardTags: ['paired']
      targetStreet: flop
  - name: Preflop Only
    constraints:
      targetStreet: preflop
''';

    final packs = const TrainingPackTemplateSetExpander().expandFromYaml(yaml);
    expect(packs.length, 2);
    expect(packs[0].name, 'Paired Boards');
    expect(packs[0].spots.length, 1);
    expect(packs[0].spots.first.id, 's2');
    expect(packs[0].meta['origin'], 'template-set');
    expect(packs[1].name, 'Preflop Only');
    expect(packs[1].spots.length, 1);
    expect(packs[1].spots.first.id, 's1');
    expect(packs[1].meta['origin'], 'template-set');
  });
}
