import 'dart:io';

import 'package:test/test.dart';
import 'package:poker_analyzer/services/training_pack_template_compiler.dart';

void main() {
  const yamlA = '''
baseSpot:
  id: a
  hand:
    heroCards: Ah Kh
    position: btn
    heroIndex: 0
    playerCount: 2
    board: []
variations:
  - overrides:
      board:
        - [As, Kd, Qc]
''';

  const yamlB = '''
baseSpot:
  id: b
  hand:
    heroCards: Qh Qd
    position: sb
    heroIndex: 0
    playerCount: 2
    board: []
variations:
  - overrides:
      board:
        - [2h, 2c, 9d]
''';

  test('compileYamls expands multiple sets', () {
    final compiler = TrainingPackTemplateCompiler();
    final spots = compiler.compileYamls([yamlA, yamlB]);
    expect(spots, hasLength(2));
    final ids = spots.map((s) => s.templateSourceId).toSet();
    expect(ids, {'a', 'b'});
  });

  test('compileYamlsGrouped groups by base id', () {
    final compiler = TrainingPackTemplateCompiler();
    final grouped = compiler.compileYamlsGrouped([yamlA, yamlB]);
    expect(grouped.keys.toSet(), {'a', 'b'});
    expect(grouped['a'], hasLength(1));
    expect(grouped['b'], hasLength(1));
  });

  test('compileFiles reads from disk', () async {
    final dir = await Directory.systemTemp.createTemp('tpl');
    final fileA = File('${dir.path}/a.yaml')..writeAsStringSync(yamlA);
    final fileB = File('${dir.path}/b.yaml')..writeAsStringSync(yamlB);
    final compiler = TrainingPackTemplateCompiler();
    final spots = await compiler.compileFiles([fileA.path, fileB.path]);
    expect(spots, hasLength(2));
  });
}
