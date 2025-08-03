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
}
