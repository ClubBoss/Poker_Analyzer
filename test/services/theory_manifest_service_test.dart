import 'dart:io';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:poker_analyzer/services/config_source.dart';
import 'package:poker_analyzer/services/theory_integrity_sweeper.dart';
import 'package:poker_analyzer/services/theory_manifest_service.dart';
import 'package:poker_analyzer/services/theory_yaml_canonicalizer.dart';
import 'package:poker_analyzer/services/theory_yaml_safe_reader.dart';
import 'package:test/test.dart';

void main() {
  Future<ConfigSource> _config() async {
    final cfg = File('config.yaml')..writeAsStringSync('theory.reader.strict: false\n');
    return ConfigSource.from(configFile: cfg.path);
  }

  test('generate and verify pass', () async {
    final tmp = await Directory.systemTemp.createTemp();
    Directory.current = tmp.path;
    final dir = Directory('packs')..createSync();
    final file = File(p.join(dir.path, 'pack.yaml'));
    final body = 'name: good\n';
    final canon = const TheoryYamlCanonicalizer().canonicalize({'name': 'good'});
    final hash = sha256.convert(utf8.encode(canon)).toString();
    file.writeAsStringSync(
        '# x-hash: $hash | x-ver: 1 | x-ts: 0 | x-hash-algo: sha256-canon@v1\n$body');

    final manifest = TheoryManifestService();
    await manifest.generate([dir.path]);
    await manifest.save();

    // touch file without changing content
    file.writeAsStringSync(file.readAsStringSync());

    final config = await _config();
    final sweeper = TheoryIntegritySweeper(
      config: config,
      reader: TheoryYamlSafeReader(config: config),
    );
    final report = await sweeper.run(
      dirs: [dir.path],
      dryRun: true,
      heal: false,
      manifestPath: 'theory_manifest.json',
      check: true,
    );
    expect(
      (report.counters['needs_heal'] ?? 0) +
          (report.counters['needs_upgrade'] ?? 0) +
          (report.counters['failed'] ?? 0),
      0,
    );
  });

  test('corrupt file fails verify', () async {
    final tmp = await Directory.systemTemp.createTemp();
    Directory.current = tmp.path;
    final dir = Directory('packs')..createSync();
    final file = File(p.join(dir.path, 'pack.yaml'));
    final body = 'name: good\n';
    final canon = const TheoryYamlCanonicalizer().canonicalize({'name': 'good'});
    final hash = sha256.convert(utf8.encode(canon)).toString();
    file.writeAsStringSync(
        '# x-hash: $hash | x-ver: 1 | x-ts: 0 | x-hash-algo: sha256-canon@v1\n$body');

    final manifest = TheoryManifestService();
    await manifest.generate([dir.path]);
    await manifest.save();

    // corrupt file
    file.writeAsStringSync(
        '# x-hash: $hash | x-ver: 1 | x-ts: 0 | x-hash-algo: sha256-canon@v1\nname: bad\n');

    final config = await _config();
    final sweeper = TheoryIntegritySweeper(
      config: config,
      reader: TheoryYamlSafeReader(config: config),
    );
    final report = await sweeper.run(
      dirs: [dir.path],
      dryRun: true,
      heal: false,
      manifestPath: 'theory_manifest.json',
      check: true,
    );
    expect(report.counters['failed'], greaterThan(0));
  });

  test('needs_upgrade then fix and update manifest', () async {
    final tmp = await Directory.systemTemp.createTemp();
    Directory.current = tmp.path;
    final dir = Directory('packs')..createSync();
    final file = File(p.join(dir.path, 'legacy.yaml'));
    final body = 'name: test\n';
    final legacyHash = sha256.convert(utf8.encode(body)).toString();
    file.writeAsStringSync('# x-hash: $legacyHash | x-ver: 1 | x-ts: 0\n$body');

    final manifest = TheoryManifestService();
    await manifest.generate([dir.path]);
    await manifest.save();

    var config = await _config();
    var sweeper = TheoryIntegritySweeper(
      config: config,
      reader: TheoryYamlSafeReader(config: config),
    );
    var report = await sweeper.run(
      dirs: [dir.path],
      dryRun: true,
      heal: false,
      manifestPath: 'theory_manifest.json',
      check: true,
    );
    expect(report.counters['needs_upgrade'], greaterThan(0));

    // fix
    await sweeper.run(dirs: [dir.path], dryRun: false);
    await manifest.load();
    await manifest.update([dir.path]);
    await manifest.save();

    config = await _config();
    sweeper = TheoryIntegritySweeper(
      config: config,
      reader: TheoryYamlSafeReader(config: config),
    );
    report = await sweeper.run(
      dirs: [dir.path],
      dryRun: true,
      heal: false,
      manifestPath: 'theory_manifest.json',
      check: true,
    );
    expect(report.counters['needs_upgrade'], 0);
  });
}
