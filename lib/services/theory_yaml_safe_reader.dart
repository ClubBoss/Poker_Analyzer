// lib/services/theory_yaml_safe_reader.dart
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaml/yaml.dart';

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
  TheoryYamlSafeReader({AutogenStatusDashboardService? dashboard})
      : _dashboard = dashboard ?? AutogenStatusDashboardService.instance;

  final AutogenStatusDashboardService _dashboard;

  static final _headerRe = RegExp(
      r'^#\s*x-hash:\s*([0-9a-f]{64})\s*\|\s*x-ver:\s*(\d+).*$');

  Future<Map<String, dynamic>> read({
    required String path,
    required String schema,
    bool autoHeal = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final healEnabled =
        autoHeal && (prefs.getBool('theory.reader.autoHeal') ?? true);
    final strict = prefs.getBool('theory.reader.strict') ?? true;
    final file = File(path);
    try {
      final lines = await file.readAsLines();
      if (lines.isEmpty) throw TheoryReadCorruption('empty_file');
      final header = lines.first.trim();
      final m = _headerRe.firstMatch(header);
      if (m == null) throw TheoryReadCorruption('missing_header');
      final expected = m.group(1)!;
      final body = lines.skip(1).join('\n');
      final hash = sha256.convert(utf8.encode(body)).toString();
      if (hash != expected) {
        AutogenPipelineEventLoggerService.log('theory.hash_mismatch', path);
        if (healEnabled) {
          final restored = await _tryHeal(path, schema, strict);
          if (restored != null) {
            AutogenPipelineEventLoggerService.log(
                'theory.autoheal_success', path);
            return restored;
          }
          AutogenPipelineEventLoggerService.log(
              'theory.autoheal_failed', path);
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
      final map = _parse(body);
      _enforceSchema(map, schema, strict);
      AutogenPipelineEventLoggerService.log('theory.read_ok', path);
      return map;
    } catch (e) {
      if (e is TheoryReadCorruption) rethrow;
      AutogenPipelineEventLoggerService.log(
          'theory.read_schema_error', '$path:$e');
      rethrow;
    }
  }

  Map<String, dynamic> _parse(String yaml) {
    final doc = loadYaml(yaml);
    return jsonDecode(jsonEncode(doc)) as Map<String, dynamic>;
  }

  void _enforceSchema(
      Map<String, dynamic> map, String schema, bool strict) {
    if (!strict) return;
    if (schema == 'TemplateSet') {
      // Throws if invalid
      TrainingPackTemplateV2.fromJson(map);
    }
  }

  Future<Map<String, dynamic>?> _tryHeal(
      String path, String schema, bool strict) async {
    final rel = p.relative(path);
    final base = p.basename(rel);
    final backupDir = Directory(p.join('theory_backups', p.dirname(rel)));
    if (!backupDir.existsSync()) return null;
    final files = backupDir
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
        final body = lines.skip(1).join('\n');
        final hash = sha256.convert(utf8.encode(body)).toString();
        if (hash != expected) continue;
        final map = _parse(body);
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
