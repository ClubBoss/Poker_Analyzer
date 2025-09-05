// Demos steps linter.
// Usage:
//   dart run tooling/demos_steps_lint.dart
//   dart run tooling/demos_steps_lint.dart --module <id>
//   dart run tooling/demos_steps_lint.dart --json <path>
//   dart run tooling/demos_steps_lint.dart --quiet
//
// Scans content/*/v1/demos.jsonl and reports demos that have fewer than 4 steps.
// Outputs a deterministic JSON report and a one-line summary:
//   DEMO-STEPS modules=<N> failing=<F>
// Exits 0 if F==0, else 1.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  String? filter;
  String jsonPath = 'build/demos_steps.json';
  var quiet = false;

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--quiet') {
      quiet = true;
    } else if (a == '--json' && i + 1 < args.length) {
      jsonPath = args[++i];
    } else if (a == '--module' && i + 1 < args.length) {
      filter = args[++i];
    } else if (!a.startsWith('--') && a != 'all' && filter == null) {
      // Back-compat single positional module id.
      filter = a;
    }
  }

  final modules = _discoverModules(filter);

  final rows = <Map<String, dynamic>>[];
  var modulesScanned = 0;
  var totalFailing = 0;

  for (final m in modules) {
    final path = 'content/$m/v1/demos.jsonl';
    final f = File(path);
    if (!f.existsSync()) {
      continue;
    }
    modulesScanned++;
    final failing = <Map<String, dynamic>>[];
    List<String> lines;
    try {
      lines = f.readAsLinesSync();
    } catch (_) {
      // IO error: treat as no failing entries but still counted as scanned.
      lines = const <String>[];
    }
    for (var i = 0; i < lines.length; i++) {
      final raw = lines[i].trim();
      if (raw.isEmpty) continue;
      try {
        final obj = jsonDecode(raw);
        if (obj is! Map<String, dynamic>) continue;
        final id = _coerceId(obj['id'], i + 1);
        final steps = obj['steps'];
        final stepsCount = steps is List ? steps.length : 0;
        if (stepsCount < 4) {
          failing.add({'id': id, 'steps': stepsCount});
        }
      } catch (_) {
        // Skip unparsable line.
      }
    }
    // Deterministic by demo id.
    failing.sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));
    if (failing.isNotEmpty) {
      rows.add({'module': m, 'items': failing});
      totalFailing += failing.length;
    }
  }

  // Deterministic by module id.
  rows.sort((a, b) => (a['module'] as String).compareTo(b['module'] as String));

  final payload = <String, dynamic>{
    'rows': rows,
    'summary': {'modules': modulesScanned, 'failing_demos': totalFailing},
  };

  // Write JSON (idempotent path, deterministic content)
  try {
    final out = File(jsonPath);
    out.parent.createSync(recursive: true);
    out.writeAsStringSync(jsonEncode(payload));
  } catch (e) {
    stderr.writeln('write error: $e');
    // continue to print summary and exit with code according to failures
  }

  // Touch 'quiet' to avoid unused warning; always print one-liner per spec.
  if (quiet) {
    // Quiet mode still prints summary; no additional logs.
  }
  // Summary one-liner
  stdout.writeln('DEMO-STEPS modules=$modulesScanned failing=$totalFailing');
  if (totalFailing > 0) exitCode = 1;
}

List<String> _discoverModules(String? only) {
  final root = Directory('content');
  if (!root.existsSync()) return <String>[];
  final out = <String>[];
  for (final e in root.listSync()) {
    if (e is! Directory) continue;
    final id = _basename(e.path);
    if (id.isEmpty || id.startsWith('_')) continue;
    if (only != null && id != only) continue;
    final v1 = Directory('${e.path}/v1');
    if (v1.existsSync()) out.add(id);
  }
  out.sort();
  return out;
}

String _basename(String path) {
  final norm = path.replaceAll('\\', '/');
  var s = norm;
  if (s.endsWith('/')) s = s.substring(0, s.length - 1);
  final idx = s.lastIndexOf('/');
  return idx == -1 ? s : s.substring(idx + 1);
}

String _coerceId(dynamic id, int lineNo) {
  if (id is String && id.isNotEmpty) return id;
  return 'unknown-$lineNo';
}
