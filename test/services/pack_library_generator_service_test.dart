import 'dart:io';

import 'package:test/test.dart';
import 'package:poker_analyzer/services/pack_library_generator_service.dart';

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

  test('generate writes pack_library.g.dart', () async {
    final dir = await Directory.systemTemp.createTemp('libgen');
    final fileA = File('${dir.path}/a.yaml')..writeAsStringSync(yamlA);
    final fileB = File('${dir.path}/b.yaml')..writeAsStringSync(yamlB);
    final outPath = '${dir.path}/pack_library.g.dart';

    final generator = PackLibraryGeneratorService();
    await generator.generate([fileA.path, fileB.path], outPath: outPath);

    final generated = await File(outPath).readAsString();
    expect(generated.contains('packLibrary'), isTrue);
    expect(generated.contains('TrainingPackSpot.fromJson'), isTrue);

    final entry = File('${dir.path}/main.dart');
    entry.writeAsStringSync('''
import 'dart:convert';
import 'pack_library.g.dart';

void main() {
  final keys = packLibrary.keys.toList()..sort();
  print(jsonEncode(keys));
  final spot = packLibrary['a']!.first;
  print(spot.templateSourceId);
  print(jsonEncode(spot.board));
}
''');

    final result = await Process.run('dart', [entry.path]);
    expect(result.exitCode, 0);
    final lines = (result.stdout as String).trim().split('\n');
    expect(lines[0], '["a","b"]');
    expect(lines[1], 'a');
    expect(lines[2], '["As","Kd","Qc"]');
  });
}
