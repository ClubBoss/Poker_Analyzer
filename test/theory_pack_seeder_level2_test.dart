import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/theory_pack_seeder_level2.dart';
import 'package:yaml/yaml.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('seed prepends theory spots to level2 pack', () async {
    final dir = await Directory.systemTemp.createTemp('level2_pack');
    final file = File('${dir.path}/test.yaml');
    await file.writeAsString('''
id: test
name: Test Pack
trainingType: mtt
bb: 20
gameType: tournament
positions:
  - co
tags:
  - level2
  - openfold
spots:
  - id: s1
    title: AKo CO 20bb
    villainAction: none
    heroOptions:
      - open
      - fold
    hand:
      heroCards: As Kc
      position: co
      heroIndex: 0
      playerCount: 6
      stacks:
        "0": 20
        "1": 20
spotCount: 1
meta:
  schemaVersion: 2.0.0
''');

    final seeder = TheoryPackSeederLevel2();
    final updated = await seeder.seed(dir: dir.path);
    expect(updated, contains(file.path));

    final updatedYaml = loadYaml(await file.readAsString()) as YamlMap;
    final spots = updatedYaml['spots'] as YamlList;
    expect(spots.length, 2);
    final first = spots.first as YamlMap;
    expect(first['type'], 'theory');
    expect(updatedYaml['meta']['hasTheory'], true);
    expect(updatedYaml['spotCount'], 2);

    dir.deleteSync(recursive: true);
  });
}
