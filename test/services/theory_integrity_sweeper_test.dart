import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:poker_analyzer/services/config_source.dart';
import 'package:poker_analyzer/services/theory_integrity_sweeper.dart';
import 'package:poker_analyzer/services/theory_yaml_canonicalizer.dart';
import 'package:poker_analyzer/services/theory_yaml_safe_reader.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('upgrades legacy headers and prunes backups', () async {
    final tmp = await Directory.systemTemp.createTemp();
    Directory.current = tmp.path;
    final cfgFile = File('config.yaml')
      ..writeAsStringSync(
        'theory.backups.keep: 1\n'
        'theory.sweep.maxParallel: 2\n'
        'theory.reader.strict: false\n',
      );
    final config = await ConfigSource.from(configFile: cfgFile.path);

    final dir = Directory('theory')..createSync(recursive: true);
    final file = File(p.join(dir.path, 'legacy.yaml'));
    final body = 'name: test\n';
    final legacyHash = sha256.convert(utf8.encode(body)).toString();
    file.writeAsStringSync('# x-hash: $legacyHash | x-ver: 1 | x-ts: 0\n$body');

    // create extra backups to prune
    final backupDir = Directory(p.join('theory_backups', 'theory'))
      ..createSync(recursive: true);
    File(
      p.join(backupDir.path, 'legacy.yaml.1.yaml'),
    ).writeAsStringSync('# backup\n');
    File(
      p.join(backupDir.path, 'legacy.yaml.2.yaml'),
    ).writeAsStringSync('# backup\n');

    final sweeper = TheoryIntegritySweeper(
      config: config,
      reader: TheoryYamlSafeReader(config: config),
    );
    final report = await sweeper.run(dirs: [dir.path], dryRun: false);
    final entry = report.entries.firstWhere((e) => e.file == file.path);
    expect(entry.action, 'upgraded');
    final firstLine = file.readAsLinesSync().first;
    expect(firstLine.contains('x-hash-algo'), isTrue);
    // backups pruned to keep
    final remaining = backupDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.contains('legacy.yaml'))
        .length;
    expect(remaining, 1);
  });

  test('heals corrupt file from backup and is idempotent', () async {
    final tmp = await Directory.systemTemp.createTemp();
    Directory.current = tmp.path;
    final cfgFile = File('config.yaml')
      ..writeAsStringSync(
        'theory.backups.keep: 1\n'
        'theory.reader.strict: false\n',
      );
    final config = await ConfigSource.from(configFile: cfgFile.path);

    final dir = Directory('packs')..createSync();
    final file = File(p.join(dir.path, 'pack.yaml'));
    final goodBody = 'name: good\n';
    final canon = const TheoryYamlCanonicalizer().canonicalize({
      'name': 'good',
    });
    final goodHash = sha256.convert(utf8.encode(canon)).toString();
    file.writeAsStringSync(
      '# x-hash: $goodHash | x-ver: 1 | x-ts: 0 | x-hash-algo: sha256-canon@v1\n$goodBody',
    );

    // corrupt main file
    file.writeAsStringSync(
      '# x-hash: $goodHash | x-ver: 1 | x-ts: 0 | x-hash-algo: sha256-canon@v1\nname: bad\n',
    );

    // good backup
    final backupDir = Directory(p.join('theory_backups', 'packs'))
      ..createSync(recursive: true);
    File(p.join(backupDir.path, 'pack.yaml.1.yaml')).writeAsStringSync(
      '# x-hash: $goodHash | x-ver: 1 | x-ts: 0 | x-hash-algo: sha256-canon@v1\n$goodBody',
    );

    final sweeper = TheoryIntegritySweeper(
      config: config,
      reader: TheoryYamlSafeReader(config: config),
    );
    var report = await sweeper.run(dirs: [dir.path], dryRun: false);
    final entry = report.entries.firstWhere((e) => e.file == file.path);
    expect(entry.action, 'healed');
    expect(file.readAsLinesSync()[1], 'name: good');

    // re-run should be no-op
    report = await sweeper.run(dirs: [dir.path], dryRun: false);
    expect(report.entries.first.action, 'ok');
  });

  test('dryRun does not mutate', () async {
    final tmp = await Directory.systemTemp.createTemp();
    Directory.current = tmp.path;
    final cfgFile = File('config.yaml')
      ..writeAsStringSync('theory.reader.strict: false\n');
    final config = await ConfigSource.from(configFile: cfgFile.path);

    final dir = Directory('theory')..createSync();
    final file = File(p.join(dir.path, 'legacy.yaml'));
    final body = 'name: test\n';
    final legacyHash = sha256.convert(utf8.encode(body)).toString();
    file.writeAsStringSync('# x-hash: $legacyHash | x-ver: 1 | x-ts: 0\n$body');

    final sweeper = TheoryIntegritySweeper(
      config: config,
      reader: TheoryYamlSafeReader(config: config),
    );
    final report = await sweeper.run(dirs: [dir.path], dryRun: true);
    final entry = report.entries.firstWhere((e) => e.file == file.path);
    expect(entry.action, 'upgraded');
    final firstLine = file.readAsLinesSync().first;
    expect(firstLine.contains('x-hash-algo'), isFalse);
  });
}
