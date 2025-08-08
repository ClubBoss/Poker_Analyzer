import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import 'package:poker_analyzer/services/autogen_pipeline_event_logger_service.dart';
import 'package:poker_analyzer/services/config_source.dart';
import 'package:poker_analyzer/services/theory_yaml_canonicalizer.dart';
import 'package:poker_analyzer/services/theory_yaml_safe_reader.dart';

Future<ConfigSource> _config() => ConfigSource.from();

void main() {
  setUp(() async {
    final backupRoot = Directory('theory_backups');
    if (backupRoot.existsSync()) backupRoot.deleteSync(recursive: true);
    AutogenPipelineEventLoggerService.clearLog();
  });

  test('valid read passes', () async {
    final config = await _config();
    final dir = Directory('tmp_reader_test')..createSync();
    final path = p.join(dir.path, 'pack.yaml');
    const body =
        'id: t1\nname: Test\ntrainingType: theory\ngameType: cash\nbb: 1\nspots: []\n';
    final map = jsonDecode(jsonEncode(loadYaml(body))) as Map<String, dynamic>;
    final canon = const TheoryYamlCanonicalizer().canonicalize(map);
    final hash = sha256.convert(utf8.encode(canon)).toString();
    await File(path).writeAsString(
      '# x-hash: $hash | x-ver: 1 | x-ts: now | x-hash-algo: sha256-canon@v1\n$body',
    );
    final result = await TheoryYamlSafeReader(
      config: config,
    ).read(path: path, schema: 'TemplateSet');
    expect(result['id'], 't1');
  });

  test('legacy header upgrade is atomic', () async {
    final config = await _config();
    final dir = Directory('tmp_reader_test')..createSync();
    final path = p.join(dir.path, 'legacy.yaml');
    const body =
        'id: l\nname: L\ntrainingType: theory\ngameType: cash\nbb: 1\nspots: []\n';
    final legacyHash = sha256.convert(utf8.encode(body)).toString();
    await File(
      path,
    ).writeAsString('# x-hash: $legacyHash | x-ver: 1 | x-ts: now\n$body');
    // Simulate crash leaving a tmp file.
    File('$path.tmp').writeAsStringSync('stale');
    final reader = TheoryYamlSafeReader(config: config);
    await reader.read(path: path, schema: 'TemplateSet');
    expect(File('$path.tmp').existsSync(), isFalse);
    final header = File(path).readAsLinesSync().first;
    expect(header.contains('x-hash-algo: sha256-canon@v1'), isTrue);
  });

  test('tampered body heals from backup', () async {
    final config = await _config();
    final dir = Directory('tmp_reader_test')..createSync();
    final path = p.join(dir.path, 'heal.yaml');
    const body =
        'id: a\nname: A\ntrainingType: theory\ngameType: cash\nbb: 1\nspots: []\n';
    final map = jsonDecode(jsonEncode(loadYaml(body))) as Map<String, dynamic>;
    final canon = const TheoryYamlCanonicalizer().canonicalize(map);
    final hash = sha256.convert(utf8.encode(canon)).toString();
    await File(path).writeAsString(
      '# x-hash: $hash | x-ver: 1 | x-ts: now | x-hash-algo: sha256-canon@v1\n$body',
    );
    final rel = p.relative(path);
    final backup = File('theory_backups/$rel.1.yaml')
      ..parent.createSync(recursive: true);
    await backup.writeAsString(
      '# x-hash: $hash | x-ver: 1 | x-ts: now | x-hash-algo: sha256-canon@v1\n$body',
    );
    final lines = await File(path).readAsLines();
    lines[1] = 'name: corrupt';
    await File(path).writeAsString(lines.join('\n'));
    final result = await TheoryYamlSafeReader(
      config: config,
    ).read(path: path, schema: 'TemplateSet');
    expect(result['name'], 'A');
  });
}
