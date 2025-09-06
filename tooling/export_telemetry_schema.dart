// Export deterministic telemetry schema JSON for UI logging and rollups.
// Usage:
//   dart run tooling/export_telemetry_schema.dart
// Writes build/telemetry_schema.json and prints: TLMT-SCHEMA events=4
// ASCII-only. No external deps.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final outPath = 'build/telemetry_schema.json';
  Directory('build').createSync(recursive: true);

  final payload = {
    'events': [
      {
        'type': 'view',
        'required': ['ts_iso', 'module', 'stage', 'client_id', 'locale', 'app_ver'],
        'optional': ['token', 'spot_kind'],
      },
      {
        'type': 'answer',
        'required': [
          'ts_iso',
          'module',
          'stage',
          'client_id',
          'locale',
          'app_ver',
          'correct',
          'latency_ms'
        ],
        'optional': ['token', 'spot_kind'],
      },
      {
        'type': 'hint',
        'required': ['ts_iso', 'module', 'stage', 'client_id', 'locale', 'app_ver'],
        'optional': ['token'],
      },
      {
        'type': 'fail_type',
        'required': ['ts_iso', 'module', 'stage', 'client_id', 'locale', 'app_ver', 'reason'],
        'optional': ['token'],
      },
    ],
    'enums': {
      'stage': ['theory', 'demos', 'drills'],
      'locale': ['en', 'ru'],
    },
    'rollups': [
      {'by': 'module'},
      {'by': 'token'},
      {'by': 'spot_kind'},
    ],
  };

  File(outPath).writeAsStringSync(jsonEncode(payload));
  stdout.writeln('TLMT-SCHEMA events=4');
}

