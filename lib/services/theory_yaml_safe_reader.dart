// lib/services/theory_yaml_safe_reader.dart
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'config_source.dart';
import 'theory_yaml_canonicalizer.dart';

import '../models/autogen_status.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'autogen_status_dashboard_service.dart';
import 'autogen_pipeline_event_logger_service.dart';

class TheoryReadCorruption implements Exception {
  final String message;
  TheoryReadCorruption(this.message);
  @override
  String toString() => 'TheoryReadCorruption: $message';
}

/// Safely reads theory YAML files with checksum verification and auto-heal.
class TheoryYamlSafeReader {
  TheoryYamlSafeReader({
    AutogenStatusDashboardService? dashboard,
    ConfigSource? config,
  }) : _dashboard = dashboard ?? AutogenStatusDashboardService.instance,
       _config = config ?? ConfigSource.empty();

  final AutogenStatusDashboardService _dashboard;
  final ConfigSource _config;

  static final _headerRe = RegExp(
    r'^#\s*x-hash:\s*([0-9a-f]{64})\s*\|\s*x-ver:\s*(\d+)\s*\|\s*x-ts:\s*([^|]+?)(?:\s*\|\s*x-hash-algo:\s*(\S+))?(?:\s*\|\s*(.*))?$',
  );

  Future<Map<String, dynamic>> read({
    required String path,
    required String schema,
    bool autoHeal = true,
  }) async {
    final healEnabled =
        autoHeal && (_config.getBool('theory.reader.autoHeal') ?? true);
    final strict = _config.getBool('theory.reader.strict') ?? true;
    final file = File(path);
    try {
      final lines = await file.readAsLines();
      if (lines.isEmpty) throw TheoryReadCorruption('empty_file');
      final header = lines.first.trim();
      final m = _headerRe.firstMatch(header);
      if (m == null) throw TheoryReadCorruption('missing_header');
      final expected = m.group(1)!;
      final version = int.parse(m.group(2)!); // unused but reserved
      final ts = m.group(3)!;
      final algo = m.group(4);
      final meta = m.group(5);
      final body = lines.skip(1).join('\n');

      Map<String, dynamic>? map;
      String hash;
      if (algo == 'sha256-canon@v1') {
        map = _parse(body);
        final canon = const TheoryYamlCanonicalizer().canonicalize(map);
        hash = sha256.convert(utf8.encode(canon)).toString();
        if (hash != expected) {
          AutogenPipelineEventLoggerService.log(
            'theory.hash_canon_mismatch',
            path,
          );
          if (healEnabled) {
            final restored = await _tryHeal(path, schema, strict);
            if (restored != null) {
              AutogenPipelineEventLoggerService.log(
                'theory.autoheal_success',
                path,
              );
              return restored;
            }
            AutogenPipelineEventLoggerService.log(
              'theory.autoheal_failed',
              path,
            );
          }
          _dashboard.update(
            'TheoryReader',
            AutogenStatus(
              currentStage: 'corrupt',
              action: 'corrupt',
              file: path,
              lastError: 'checksum_mismatch',
            ),
          );
          throw TheoryReadCorruption('checksum_mismatch');
        }
      } else {
        hash = sha256.convert(utf8.encode(body)).toString();
        if (hash != expected) {
          AutogenPipelineEventLoggerService.log('theory.hash_mismatch', path);
          if (healEnabled) {
            final restored = await _tryHeal(path, schema, strict);
            if (restored != null) {
              AutogenPipelineEventLoggerService.log(
                'theory.autoheal_success',
                path,
              );
              return restored;
            }
            AutogenPipelineEventLoggerService.log(
              'theory.autoheal_failed',
              path,
            );
          }
          _dashboard.update(
            'TheoryReader',
            AutogenStatus(
              currentStage: 'corrupt',
              action: 'corrupt',
              file: path,
              lastError: 'checksum_mismatch',
            ),
          );
          throw TheoryReadCorruption('checksum_mismatch');
        }
        AutogenPipelineEventLoggerService.log(
          'theory.hash_legacy_verified',
          path,
        );
        map = _parse(body);
        if (healEnabled) {
          // Upgrade header atomically to canonical hash
          final canon = const TheoryYamlCanonicalizer().canonicalize(map);
          final newHash = sha256.convert(utf8.encode(canon)).toString();
          final header =
              '# x-hash: $newHash | x-ver: $version | x-ts: $ts | x-hash-algo: sha256-canon@v1'
              '${meta != null ? ' | $meta' : ''}';
          final tmp = File('$path.tmp');
          if (tmp.existsSync()) {
            // Leftover from a previous crash
            try {
              tmp.deleteSync();
            } catch (_) {}
          }
          final sink = tmp.openWrite();
          sink.writeln(header);
          sink.write(body);
          await sink.flush();
          await sink.close();
          try {
            await tmp.rename(path);
          } catch (_) {
            await tmp.copy(path);
            await tmp.delete().catchError((_) {});
          }
          AutogenPipelineEventLoggerService.log('theory.hash_upgraded', path);
        }
      }

      _enforceSchema(map ?? _parse(body), schema, strict);
      AutogenPipelineEventLoggerService.log('theory.read_ok', path);
      return map;
    } catch (e) {
      if (e is TheoryReadCorruption) rethrow;
      AutogenPipelineEventLoggerService.log(
        'theory.read_schema_error',
        '$path:$e',
      );
      rethrow;
    }
  }

  Map<String, dynamic> _parse(String yaml) {
    final doc = loadYaml(yaml);
    return jsonDecode(jsonEncode(doc)) as Map<String, dynamic>;
  }

  void _enforceSchema(Map<String, dynamic> map, String schema, bool strict) {
    if (!strict) return;
    if (schema == 'TemplateSet') {
      // Throws if invalid
      TrainingPackTemplateV2.fromJson(map);
    }
  }

  Future<Map<String, dynamic>?> _tryHeal(
    String path,
    String schema,
    bool strict,
  ) async {
    final rel = p.relative(path);
    final base = p.basename(rel);
    final backupDir = Directory(p.join('theory_backups', p.dirname(rel)));
    if (!backupDir.existsSync()) return null;
    final files =
        backupDir
            .listSync()
            .whereType<File>()
            .where((f) => p.basename(f.path).startsWith('$base.'))
            .toList()
          ..sort((a, b) => b.path.compareTo(a.path));
    for (final f in files) {
      try {
        final lines = await f.readAsLines();
        if (lines.isEmpty) continue;
        final m = _headerRe.firstMatch(lines.first.trim());
        if (m == null) continue;
        final expected = m.group(1)!;
        final algo = m.group(4);
        final body = lines.skip(1).join('\n');
        Map<String, dynamic>? map;
        String hash;
        if (algo == 'sha256-canon@v1') {
          map = _parse(body);
          final canon = const TheoryYamlCanonicalizer().canonicalize(map);
          hash = sha256.convert(utf8.encode(canon)).toString();
        } else {
          hash = sha256.convert(utf8.encode(body)).toString();
          if (hash == expected) {
            map = _parse(body);
          }
        }
        if (hash != expected || map == null) continue;
        _enforceSchema(map, schema, strict);
        try {
          final corrupt = File(path);
          if (corrupt.existsSync()) {
            await corrupt.rename('$path.corrupt');
          }
          await f.rename(path);
        } catch (_) {
          await File(path).delete().catchError((_) {});
          await f.rename(path);
        }
        return map;
      } catch (_) {}
    }
    return null;
  }
}
