import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaml/yaml.dart';

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
      r'^#\s*x-hash:\s*([0-9a-f]+)\s*\|\s*x-ver:\s*(\d+)\s*\|\s*x-ts:\s*([^|]+)(?:\|\s*(.*))?\$');

  Future<void> write({
    required String path,
    required String yaml,
    required String schema,
    Map<String, String>? meta,
    String? prevHash,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final dryRun = prefs.getBool('theory.safeWriter.dryRun') ?? false;
    final keep = prefs.getInt('theory.backups.keep') ?? 10;
    final strict = prefs.getBool('theory.safeWriter.strict') ?? true;

    try {
      if (strict) {
        final map =
            jsonDecode(jsonEncode(loadYaml(yaml))) as Map<String, dynamic>;
        if (schema == 'TemplateSet') {
          TrainingPackTemplateV2.fromJson(map);
        }
      } else {
        loadYaml(yaml);
      }

      final newHash = sha256.convert(utf8.encode(yaml)).toString();
      final file = File(path);
      String? oldHash;
      var version = 0;
      if (file.existsSync()) {
        final lines = file.readAsLinesSync();
        final firstLine = lines.isEmpty ? null : lines.first;
        final match = firstLine != null ? _headerRe.firstMatch(firstLine) : null;
        if (match != null) {
          oldHash = match.group(1);
          version = int.parse(match.group(2)!);
          if (oldHash != null && (prevHash == null || prevHash != oldHash)) {
            _dashboard.update(
                'TheoryWriter',
                AutogenStatus(
                    currentStage: 'conflict', lastError: 'checksum_mismatch'));
            throw TheoryWriteConflict('checksum_mismatch');
          }
        }
        if (oldHash == newHash) {
          _dashboard.update(
              'TheoryWriter', AutogenStatus(currentStage: 'no-op', progress: 1));
          return;
        }
        final rel = p.relative(path);
        final backupPath = p.join(
            'theory_backups',
            '$rel.${DateTime.now().millisecondsSinceEpoch}.yaml');
        final backupFile = File(backupPath);
        backupFile.parent.createSync(recursive: true);
        await file.copy(backupFile.path);
        final backupDir = backupFile.parent;
        final base = p.basename(rel);
        final backups = backupDir
            .listSync()
            .whereType<File>()
            .where((f) => p.basename(f.path).startsWith('$base.'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
        if (backups.length > keep) {
          for (final f in backups.take(backups.length - keep)) {
            f.deleteSync();
          }
        }
      }

      if (dryRun) {
        _dashboard.update(
            'TheoryWriter', AutogenStatus(currentStage: 'dryRun', progress: 1));
        return;
      }

      final headerParts = <String>[
        'x-hash: $newHash',
        'x-ver: ${version + 1}',
        'x-ts: ${DateTime.now().toIso8601String()}',
        if (meta != null) ...meta.entries.map((e) => '${e.key}: ${e.value}')
      ];
      final header = '# ' + headerParts.join(' | ');
      final content = header + '\n' + yaml;
      final tmp = File(path + '.tmp');
      tmp.parent.createSync(recursive: true);
      final raf = tmp.openSync(mode: FileMode.write);
      raf.writeStringSync(content);
      raf.flushSync();
      await raf.close();
      await tmp.rename(file.path);
      _dashboard.update(
          'TheoryWriter', AutogenStatus(currentStage: 'ok', progress: 1));
    } catch (e) {
      _dashboard.update('TheoryWriter',
          AutogenStatus(currentStage: 'rollback', lastError: e.toString()));
      rethrow;
    }
  }

  static String? extractHash(String content) {
    final first = content.split('\n').first;
    final match = _headerRe.firstMatch(first);
    return match?.group(1);
  }
}
