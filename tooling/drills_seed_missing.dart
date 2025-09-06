// Seed minimal drills.jsonl for modules that lack it.
// Usage:
//   dart run tooling/drills_seed_missing.dart [--module <id>] [--dry-run] [--write] [--quiet]
//
// Behavior:
// - Scans content/*/v1 modules. If drills.jsonl exists, skip.
// - For missing drills.jsonl, writes 10 JSON lines with fields:
//   {"id":"auto_drill_<n>","spot_kind":"<allowlist_or_none>","targets":["<allowlist_or_call>"],"prompt":"Auto-seeded drill (placeholder)","answer":"call","rationale":"auto","difficulty":1}
// - spot_kind: first non-"none" entry from tooling/allowlists/spotkind_allowlist_<module>.txt if present; else "none".
// - targets: first token from tooling/allowlists/target_tokens_allowlist_<module>.txt if present and not "none"; else ["call"].
// - ASCII-only, deterministic, idempotent. Exit 0 unless I/O error on write.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  String? onlyModule;
  var write = false;
  var dryRun = false;
  var quiet = false;

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--module' && i + 1 < args.length) {
      onlyModule = args[++i];
    } else if (a == '--write') {
      write = true;
    } else if (a == '--dry-run') {
      dryRun = true;
    } else if (a == '--quiet') {
      quiet = true;
    }
  }

  final modules = _discoverModules(onlyModule);
  var modulesScanned = 0;
  var wrote = 0;
  var skipped = 0;
  var ioError = false;

  for (final m in modules) {
    modulesScanned++;
    final dir = Directory('content/$m/v1');
    if (!dir.existsSync()) {
      skipped++;
      continue;
    }
    final path = '${dir.path}/drills.jsonl';
    final file = File(path);
    if (file.existsSync()) {
      skipped++;
      continue;
    }

    final spotKind = _firstAllowSpotKind(m) ?? 'none';
    final target = _firstAllowTargetToken(m) ?? 'call';

    final lines = <String>[];
    for (var i = 1; i <= 10; i++) {
      final obj = <String, Object?>{
        'id': 'auto_drill_$i',
        'spot_kind': spotKind,
        'target': [target],
        'prompt': 'Auto-seeded drill (placeholder)',
        'answer': 'call',
        'rationale': 'auto',
        'difficulty': 1,
      };
      lines.add(jsonEncode(obj));
    }
    final body = lines.join('\n') + '\n';

    if (write && !dryRun) {
      try {
        dir.createSync(recursive: true);
        file.writeAsStringSync(body);
        wrote++;
      } catch (e) {
        if (!quiet) stderr.writeln('write error: $path: $e');
        ioError = true;
      }
    } else {
      // no-op in dry-run or when --write not provided
      skipped++;
    }
  }

  stdout.writeln(
    'DRILLS-SEED modules=$modulesScanned wrote=$wrote skipped=$skipped',
  );
  if (ioError && write && !dryRun) exitCode = 1;
}

String? _firstAllowSpotKind(String module) {
  final path = 'tooling/allowlists/spotkind_allowlist_${module}.txt';
  final f = File(path);
  if (!f.existsSync()) return null;
  try {
    for (final raw in f.readAsLinesSync()) {
      final l = raw.trim();
      if (l.isEmpty || l.startsWith('#')) continue;
      if (l == 'none') continue;
      return l;
    }
  } catch (_) {}
  return null;
}

String? _firstAllowTargetToken(String module) {
  final path = 'tooling/allowlists/target_tokens_allowlist_${module}.txt';
  final f = File(path);
  if (!f.existsSync()) return null;
  try {
    for (final raw in f.readAsLinesSync()) {
      final l = raw.trim();
      if (l.isEmpty || l.startsWith('#')) continue;
      if (l == 'none') continue;
      return l;
    }
  } catch (_) {}
  return null;
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
