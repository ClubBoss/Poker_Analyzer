import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('l3 metrics smoke', () async {
    const jsonPath = 'build/reports/l3_packrun_test.json';
    final jsonFile = File(jsonPath);
    if (!jsonFile.existsSync()) {
      final dir = Directory('build/tmp/l3/test');
      dir.createSync(recursive: true);
      final yaml = '''
spots:
  - id: a
    board: AhKhQh
    tags: [monotone]
  - id: b
    board: AhKdQc
    tags: [twoTone]
  - id: c
    board: AhKdQs
    tags: [rainbow]
''';
      File('${dir.path}/test.yaml').writeAsStringSync(yaml);
      final gen = await Process.run('dart', [
        'run',
        'tool/l3/pack_run_cli.dart',
        '--dir',
        dir.path,
        '--out',
        jsonPath,
      ]);
      if (gen.exitCode != 0) {
        throw Exception('pack run failed: ${gen.stderr}');
      }
    }

    final res = await Process.run('dart', [
      'run',
      'tool/metrics/l3_packrun_report.dart',
      '--reports',
      jsonPath,
      '--out',
      'build/reports/l3_report_test.md',
    ]);
    final stdout = (res.stdout as String).toLowerCase();
    expect(stdout, contains('jam rate'));
    final md = File('build/reports/l3_report_test.md')
        .readAsStringSync()
        .toLowerCase();
    expect(md, contains('twotone'));
    expect(md, contains('rainbow'));
  });
}
