import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('pack run cli explain smoke', () async {
    final dir = Directory.systemTemp.createTempSync();
    final yamlFile = File('${dir.path}/mini.yaml');
    yamlFile.writeAsStringSync('''
spots:
  - id: s1
    board: AsKsQs
  - id: s2
    board: AsKd9d
  - id: s3
    board: 2h7d8c
''');
    final outFile = File('${dir.path}/out.json');
    final res = await Process.run('dart', [
      'run',
      'tool/l3/pack_run_cli.dart',
      '--dir',
      dir.path,
      '--out',
      outFile.path,
      '--explain'
    ]);
    expect(res.exitCode, 0, reason: res.stderr.toString());
    final report =
        json.decode(outFile.readAsStringSync()) as Map<String, dynamic>;
    final spots = report['spots'] as List<dynamic>;
    expect(spots, hasLength(3));
    for (final spot in spots) {
      final explain =
          (spot as Map<String, dynamic>)['explain'] as Map<String, dynamic>;
      expect(explain['contrib'], isA<Map>());
      expect(explain['tags'], isA<List>());
      expect(explain['sprBucket'], isA<String>());
    }
  });
}
