import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/test.dart';

import 'package:poker_analyzer/services/theory_yaml_safe_writer.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final backupRoot = Directory('theory_backups');
    if (backupRoot.existsSync()) {
      backupRoot.deleteSync(recursive: true);
    }
    final tmp = Directory('tmp_test');
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  test('checksum mismatch -> conflict', () async {
    final dir = Directory('tmp_test')..createSync();
    final path = p.join(dir.path, 'file.yaml');
    final writer = TheoryYamlSafeWriter();
    await writer.write(path: path, yaml: 'id: 1', schema: 'raw');
    final hash = TheoryYamlSafeWriter.extractHash(await File(path).readAsString());
    expect(hash, isNotNull);
    expect(
      () async =>
          writer.write(path: path, yaml: 'id: 2', schema: 'raw', prevHash: 'dead'),
      throwsA(isA<TheoryWriteConflict>()),
    );
  });

  test('bad schema -> reject', () async {
    final dir = Directory('tmp_test')..createSync();
    final path = p.join(dir.path, 'bad.yaml');
    final writer = TheoryYamlSafeWriter();
    await expectLater(
      writer.write(path: path, yaml: '::bad::', schema: 'raw'),
      throwsA(anything),
    );
  });

  test('backup retention', () async {
    SharedPreferences.setMockInitialValues({'theory.backups.keep': 2});
    final dir = Directory('tmp_test')..createSync();
    final path = p.join(dir.path, 'keep.yaml');
    final writer = TheoryYamlSafeWriter();
    await writer.write(path: path, yaml: 'a: 1', schema: 'raw');
    var hash = TheoryYamlSafeWriter.extractHash(await File(path).readAsString());
    for (var i = 0; i < 3; i++) {
      await writer.write(
          path: path,
          yaml: 'a: ${i + 2}',
          schema: 'raw',
          prevHash: hash);
      hash = TheoryYamlSafeWriter.extractHash(await File(path).readAsString());
    }
    final backups = Directory('theory_backups')
        .listSync(recursive: true)
        .whereType<File>()
        .toList();
    expect(backups.length, 2);
  });

  test('deterministic header & ordering', () async {
    final dir = Directory('tmp_test')..createSync();
    final path = p.join(dir.path, 'hdr.yaml');
    final writer = TheoryYamlSafeWriter();
    await writer.write(path: path, yaml: 'x: 1', schema: 'raw');
    final lines1 = await File(path).readAsLines();
    expect(lines1.first.startsWith('# x-hash:'), isTrue);
    expect(lines1.first.contains('| x-ver: 1'), isTrue);
    final hash = TheoryYamlSafeWriter.extractHash(lines1.join('\n'));
    await writer.write(path: path, yaml: 'x: 1', schema: 'raw', prevHash: hash);
    final lines2 = await File(path).readAsLines();
    expect(lines2.first.contains('| x-ver: 1'), isTrue);
  });
}
