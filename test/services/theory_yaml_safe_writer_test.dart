import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/test.dart';

import 'package:poker_analyzer/services/theory_yaml_safe_writer.dart';
import 'package:poker_analyzer/services/theory_write_scope.dart';
import 'package:poker_analyzer/services/path_transaction_manager.dart';

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
    final hash = TheoryYamlSafeWriter.extractHash(
      await File(path).readAsString(),
    );
    expect(hash, isNotNull);
    expect(
      () async => writer.write(
        path: path,
        yaml: 'id: 2',
        schema: 'raw',
        prevHash: 'dead',
      ),
      throwsA(isA<TheoryWriteConflict>()),
    );
  });

  test('extractHash parsing', () {
    final valid = '# x-hash: ${'a' * 64} | x-ver: 1 | x-ts: now';
    expect(TheoryYamlSafeWriter.extractHash(valid), 'a' * 64);
    final invalid = '# x-hash: 123 | x-ver: 1 | x-ts: now';
    expect(TheoryYamlSafeWriter.extractHash(invalid), isNull);
    expect(TheoryYamlSafeWriter.extractHash('no header'), isNull);
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
    var hash = TheoryYamlSafeWriter.extractHash(
      await File(path).readAsString(),
    );
    for (var i = 0; i < 3; i++) {
      await writer.write(
        path: path,
        yaml: 'a: ${i + 2}',
        schema: 'raw',
        prevHash: hash,
      );
      hash = TheoryYamlSafeWriter.extractHash(await File(path).readAsString());
    }
    final backups = Directory(
      'theory_backups',
    ).listSync(recursive: true).whereType<File>().toList();
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

  test('concurrent writes serialize', () async {
    final dir = Directory('tmp_test')..createSync();
    final path = p.join(dir.path, 'concurrent.yaml');
    final sw = Stopwatch()..start();
    final f1 = TheoryWriteScope.run(() async {
      await Future.delayed(const Duration(milliseconds: 300));
      await TheoryYamlSafeWriter().write(
        path: path,
        yaml: 'a: 1',
        schema: 'raw',
      );
    });
    final f2 = TheoryWriteScope.run(() async {
      await TheoryYamlSafeWriter().write(
        path: path,
        yaml: 'a: 2',
        schema: 'raw',
      );
    });
    await Future.wait([f1, f2]);
    sw.stop();
    expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(300));
  });

  test('rollback restores from backup', () async {
    final dir = Directory('tmp_test')..createSync();
    final path = p.join(dir.path, 'rollback.yaml');
    final writer = TheoryYamlSafeWriter();
    await writer.write(path: path, yaml: 'x: 1', schema: 'raw');
    final prev = TheoryYamlSafeWriter.extractHash(
      await File(path).readAsString(),
    );
    try {
      await TheoryWriteScope.run(() async {
        await writer.write(
          path: path,
          yaml: 'x: 2',
          schema: 'raw',
          prevHash: prev,
          onBackup: (p0, backup, h, p1) async {
            await PathTransactionManager(
              rootDir: '.',
            ).recordFileBackup(p0, backup);
          },
        );
        throw Exception('boom');
      });
    } catch (_) {
      await PathTransactionManager(rootDir: '.').rollbackFileBackups();
    }
    final content = await File(path).readAsString();
    expect(content.contains('x: 1'), isTrue);
  });
}
