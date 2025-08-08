import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaml/yaml.dart';
import 'package:collection/collection.dart';

import '../models/autogen_status.dart';
import 'autogen_status_dashboard_service.dart';
import '../models/v2/training_pack_template_v2.dart';

class TheoryWriteConflict implements Exception {
  final String message;
  TheoryWriteConflict(this.message);
  @override
  String toString() => 'TheoryWriteConflict: ' + message;
}

class TheoryYamlSafeWriter {
  TheoryYamlSafeWriter({AutogenStatusDashboardService? dashboard})
      : _dashboard = dashboard ?? AutogenStatusDashboardService.instance;

  final AutogenStatusDashboardService _dashboard;

  static final _headerRe = RegExp(
    r'^#\s*x-hash:\s*([0-9a-f]{64})\s*\|\s*x-ver:\s*(\d+)\s*\|\s*x-ts:\s*([^\|]+?)(?:\s*\|\s*(.*))?$',
  );

  Future<void> write({
    required String path,
    required String yaml,
    required String schema,
    Map<String, String>? meta,
    String? prevHash,
    Future<void> Function(
      String path,
      String backupPath,
      String newHash,
      String? prevHash,
    )?,
    onBackup,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final dryRun = prefs.getBool('theory.safeWriter.dryRun') ?? false;
    final keep = prefs.getInt('theory.backups.keep') ?? 10;
    final strict = prefs.getBool('theory.safeWriter.strict') ?? true;

    String? oldHash;
    String? newHash;
    var version = 0;

    try {
      // validate
      if (strict) {
        final map =
            jsonDecode(jsonEncode(loadYaml(yaml))) as Map<String, dynamic>;
        if (schema == 'TemplateSet') {
          TrainingPackTemplateV2.fromJson(map);
        }
      } else {
        loadYaml(yaml);
      }

      newHash = sha256.convert(utf8.encode(yaml)).toString();

      final file = File(path);
      if (file.existsSync()) {
        final first = (await file.readAsLines()).firstOrNull ?? '';
        final m = _headerRe.firstMatch(first);
        if (m != null) {
          oldHash = m.group(1);
          version = int.parse(m.group(2)!);
          if (oldHash != null && (prevHash == null || prevHash != oldHash)) {
            _dashboard.update(
              'TheoryWriter',
              AutogenStatus(
                currentStage: 'conflict',
                action: 'conflict',
                file: path,
                prevHash: oldHash,
                newHash: newHash,
              ),
            );
            throw TheoryWriteConflict('checksum_mismatch');
          }
        }
        if (oldHash == newHash) {
          _dashboard.update(
            'TheoryWriter',
            AutogenStatus(
              currentStage: 'no-op',
              action: 'no-op',
              progress: 1,
              file: path,
              prevHash: oldHash,
              newHash: newHash,
            ),
          );
          return;
        }

        final rel = p.relative(path);
        final backupPath =
            p.join('theory_backups', '$rel.${DateTime.now().millisecondsSinceEpoch}.yaml');
        final backupFile = File(backupPath)
          ..parent.createSync(recursive: true);
        await file.copy(backupFile.path);
        if (onBackup != null) {
          await onBackup(file.path, backupFile.path, newHash, oldHash);
        }

        // prune backups (sorted lexicographically because suffix is fixed-width timestamp)
        final base = p.basename(rel);
        final backups = backupFile.parent
            .listSync()
            .whereType<File>()
            .where((f) => p.basename(f.path).startsWith('$base.'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
        for (final f in backups.take((backups.length - keep).clamp(0, backups.length))) {
          f.deleteSync();
        }
      }

      if (dryRun) {
        _dashboard.update(
          'TheoryWriter',
          AutogenStatus(
            currentStage: 'dryRun',
            action: 'no-op',
            progress: 1,
            file: path,
            prevHash: oldHash,
            newHash: newHash,
          ),
        );
        return;
      }

      final header =
          '# x-hash: $newHash | x-ver: ${version + 1} | x-ts: ${DateTime.now().toIso8601String()}';
      final tmp = File('$path.tmp')..parent.createSync(recursive: true);
      final raf = tmp.openSync(mode: FileMode.write);
      raf.writeStringSync('$header\n$yaml');
      raf.flushSync();
      await raf.close();
      await tmp.rename(path);

      _dashboard.update(
        'TheoryWriter',
        AutogenStatus(
          currentStage: 'ok',
          action: 'ok',
          progress: 1,
          file: path,
          prevHash: oldHash,
          newHash: newHash,
        ),
      );
    } catch (e) {
      _dashboard.update(
        'TheoryWriter',
        AutogenStatus(
          currentStage: 'rollback',
          lastError: e.toString(),
          file: path,
          action: 'rollback',
          prevHash: oldHash,
          newHash: newHash,
        ),
      );
      rethrow;
    }
  }

  static String? extractHash(String content) {
    final first = content.split('\n').first.trim();
    final m = _headerRe.firstMatch(first);
    return m?.group(1);
  }
}
