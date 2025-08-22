// lib/services/theory_yaml_safe_writer.dart
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaml/yaml.dart';

import 'theory_yaml_canonicalizer.dart';
import 'theory_manifest_service.dart';

import '../models/autogen_status.dart';
import 'autogen_status_dashboard_service.dart';
import '../models/v2/training_pack_template_v2.dart';

class TheoryWriteConflict implements Exception {
  final String message;
  TheoryWriteConflict(this.message);
  @override
  String toString() => 'TheoryWriteConflict: $message';
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
    )?
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
      // Validate YAML / schema and parse map for canonicalization
      final map =
          jsonDecode(jsonEncode(loadYaml(yaml))) as Map<String, dynamic>;
      if (strict && schema == 'TemplateSet') {
        // Throws if invalid
        TrainingPackTemplateV2.fromJson(map);
      }

      final canon = const TheoryYamlCanonicalizer().canonicalize(map);
      newHash = sha256.convert(utf8.encode(canon)).toString();

      final file = File(path);
      if (file.existsSync()) {
        final firstLine = file.readAsLinesSync().firstOrNull ?? '';
        final m = _headerRe.firstMatch(firstLine);
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

        // Backup current file and prune old backups
        final rel = p.relative(path);
        final backupPath = p.join(
          'theory_backups',
          '$rel.${DateTime.now().millisecondsSinceEpoch}.yaml',
        );
        final backupFile = File(backupPath);
        backupFile.parent.createSync(recursive: true);
        await file.copy(backupFile.path);
        if (onBackup != null) {
          await onBackup(file.path, backupFile.path, newHash, oldHash);
        }

        // Lexicographic prune works because suffix is fixed-width millis
        final base = p.basename(rel);
        final backups =
            backupFile.parent
                .listSync()
                .whereType<File>()
                .where((f) => p.basename(f.path).startsWith('$base.'))
                .toList()
              ..sort((a, b) => a.path.compareTo(b.path));
        final over = backups.length - keep;
        if (over > 0) {
          for (final f in backups.take(over)) {
            f.deleteSync();
          }
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

      // Atomic write via temp + rename
      final metaSuffix = (meta == null || meta.isEmpty)
          ? ''
          : meta.entries.map((e) => ' | ${e.key}: ${e.value}').join();
      final header =
          '# x-hash: $newHash | x-ver: ${version + 1} | x-ts: ${DateTime.now().toIso8601String()} | x-hash-algo: sha256-canon@v1$metaSuffix';

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

      if (prefs.getBool('theory.manifest.autoupdate') ?? false) {
        final manifest = TheoryManifestService();
        await manifest.load();
        final stat = await File(path).stat();
        manifest.updateEntry(
          p.relative(path),
          ManifestEntry(
            algo: 'sha256-canon@v1',
            hash: newHash,
            ver: version + 1,
            ts: stat.modified,
          ),
        );
        await manifest.save();
      }
    } catch (e) {
      _dashboard.update(
        'TheoryWriter',
        AutogenStatus(
          currentStage: 'rollback',
          action: 'rollback',
          lastError: e.toString(),
          file: path,
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

// Tiny convenience so we can safely read first line
extension on List<String> {
  String? get firstOrNull => isEmpty ? null : first;
}
