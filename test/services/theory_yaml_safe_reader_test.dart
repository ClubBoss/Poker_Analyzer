import 'dart:io';
import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/test.dart';

import 'package:poker_analyzer/services/theory_yaml_safe_reader.dart';
import 'package:poker_analyzer/services/theory_yaml_safe_writer.dart';
import 'package:poker_analyzer/services/autogen_pipeline_event_logger_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'theory.reader.autoHeal': true,
      'theory.reader.strict': true,
    });
    final backupRoot = Directory('theory_backups');
    if (backupRoot.existsSync()) backupRoot.deleteSync(recursive: true);
    final tmp = Directory('tmp_reader_test');
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    AutogenPipelineEventLoggerService.clearLog();
  });

  test('valid read passes', () async {
    final dir = Directory('tmp_reader_test')..createSync();
    final path = p.join(dir.path, 'pack.yaml');
    const body = 'id: t1\nname: Test\ntrainingType: theory\ngameType: cash\nbb: 1\nspots: []\n';
    await TheoryYamlSafeWriter().write(path: path, yaml: body, schema: 'TemplateSet');
    final map = await TheoryYamlSafeReader().read(path: path, schema: 'TemplateSet');
    expect(map['id'], 't1');
    final log = AutogenPipelineEventLoggerService.getLog();
    expect(log.any((e) => e.type == 'theory.read_ok'), isTrue);
  });

  test('tampered body heals from backup', () async {
    final dir = Directory('tmp_reader_test')..createSync();
    final path = p.join(dir.path, 'heal.yaml');
    const body1 = 'id: a\nname: A\ntrainingType: theory\ngameType: cash\nbb: 1\nspots: []\n';
    const body2 = 'id: b\nname: B\ntrainingType: theory\ngameType: cash\nbb: 1\nspots: []\n';
    final writer = TheoryYamlSafeWriter();
    await writer.write(path: path, yaml: body1, schema: 'TemplateSet');
    final prev = TheoryYamlSafeWriter.extractHash(await File(path).readAsString());
    await writer.write(path: path, yaml: body2, schema: 'TemplateSet', prevHash: prev);
    final lines = await File(path).readAsLines();
    lines[1] = 'id: corrupt';
    await File(path).writeAsString(lines.join('\n'));
    final map = await TheoryYamlSafeReader().read(path: path, schema: 'TemplateSet');
    expect(map['id'], 'a');
    final events = AutogenPipelineEventLoggerService.getLog();
    expect(events.any((e) => e.type == 'theory.hash_canon_mismatch'), isTrue);
    expect(events.any((e) => e.type == 'theory.autoheal_success'), isTrue);
  });

  test('no backup throws', () async {
    final dir = Directory('tmp_reader_test')..createSync();
    final path = p.join(dir.path, 'nobak.yaml');
    const body = 'id: x\nname: X\ntrainingType: theory\ngameType: cash\nbb: 1\nspots: []\n';
    await TheoryYamlSafeWriter().write(path: path, yaml: body, schema: 'TemplateSet');
    final lines = await File(path).readAsLines();
    lines[1] = 'id: bad';
    await File(path).writeAsString(lines.join('\n'));
    expect(
      () => TheoryYamlSafeReader().read(path: path, schema: 'TemplateSet'),
      throwsA(isA<TheoryReadCorruption>()),
    );
    final events = AutogenPipelineEventLoggerService.getLog();
    expect(events.any((e) => e.type == 'theory.autoheal_failed'), isTrue);
  });

  test('legacy header migrates to v2', () async {
    final dir = Directory('tmp_reader_test')..createSync();
    final path = p.join(dir.path, 'legacy.yaml');
    const body =
        'id: l\nname: L\ntrainingType: theory\ngameType: cash\nbb: 1\nspots: []\n';
    final legacyHash = sha256.convert(utf8.encode(body)).toString();
    await File(path).writeAsString(
        '# x-hash: $legacyHash | x-ver: 1 | x-ts: now\n$body');
    final map =
        await TheoryYamlSafeReader().read(path: path, schema: 'TemplateSet');
    expect(map['id'], 'l');
    final header = (await File(path).readAsLines()).first;
    expect(header.contains('x-hash-algo: sha256-canon@v1'), isTrue);
    final events = AutogenPipelineEventLoggerService.getLog();
    expect(events.any((e) => e.type == 'theory.hash_legacy_verified'), isTrue);
    expect(events.any((e) => e.type == 'theory.hash_upgraded'), isTrue);
  });

  test('mixed backup set restore', () async {
    final dir = Directory('tmp_reader_test')..createSync();
    final path = p.join(dir.path, 'mix.yaml');
    const body1 =
        'id: a\nname: A\ntrainingType: theory\ngameType: cash\nbb: 1\nspots: []\n';
    const body2 =
        'id: b\nname: B\ntrainingType: theory\ngameType: cash\nbb: 1\nspots: []\n';
    final writer = TheoryYamlSafeWriter();
    await writer.write(path: path, yaml: body1, schema: 'TemplateSet');
    final legacyHash = sha256.convert(utf8.encode(body1)).toString();
    final rel = p.relative(path);
    final ts1 = DateTime.now().millisecondsSinceEpoch - 1000;
    final legacyBackup = File('theory_backups/$rel.$ts1.yaml')
      ..parent.createSync(recursive: true);
    await legacyBackup
        .writeAsString('# x-hash: $legacyHash | x-ver: 1 | x-ts: now\n$body1');
    final prev = TheoryYamlSafeWriter.extractHash(await File(path).readAsString());
    await writer.write(path: path, yaml: body2, schema: 'TemplateSet', prevHash: prev);
    // Corrupt latest (v2) backup
    final backupDir = legacyBackup.parent;
    final latest = backupDir
        .listSync()
        .whereType<File>()
        .reduce((a, b) => a.path.compareTo(b.path) > 0 ? a : b);
    final blines = await latest.readAsLines();
    blines[1] = 'id: corrupt';
    await latest.writeAsString(blines.join('\n'));
    // Corrupt main file
    final lines = await File(path).readAsLines();
    lines[1] = 'id: bad';
    await File(path).writeAsString(lines.join('\n'));
    final map =
        await TheoryYamlSafeReader().read(path: path, schema: 'TemplateSet');
    expect(map['id'], 'a');
    final events = AutogenPipelineEventLoggerService.getLog();
    expect(events.any((e) => e.type == 'theory.hash_canon_mismatch'), isTrue);
    expect(events.any((e) => e.type == 'theory.autoheal_success'), isTrue);
  });

  test('bad schema throws', () async {
    final dir = Directory('tmp_reader_test')..createSync();
    final path = p.join(dir.path, 'bad.yaml');
    await TheoryYamlSafeWriter().write(path: path, yaml: 'id: 1', schema: 'raw');
    expect(
      () => TheoryYamlSafeReader().read(path: path, schema: 'TemplateSet'),
      throwsA(anything),
    );
    final events = AutogenPipelineEventLoggerService.getLog();
    expect(events.any((e) => e.type == 'theory.read_schema_error'), isTrue);
  });
}
