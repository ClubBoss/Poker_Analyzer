// Probe content files for first non-ASCII code point per file.
// Usage:
//   dart run tooling/ascii_probe.dart [--module <id>] [--json <path>] [--quiet]
//
// Scans content/*/v1/{theory.md,demos.jsonl,drills.jsonl}.
// Outputs JSON: {"rows":[{"file":"<path>","codepoint":"U+XXXX","sample":"<ascii-safe preview>"},...],
//                 "summary":{"files":N,"offenders":K}}
// Always exits 0. ASCII-only output.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  String? onlyModule;
  String? jsonPath;
  bool quiet = false;
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--module' && i + 1 < args.length) {
      onlyModule = args[++i];
    } else if (a == '--json' && i + 1 < args.length) {
      jsonPath = args[++i];
    } else if (a == '--quiet') {
      quiet = true;
    }
  }

  final files = _collectFiles(onlyModule);
  final rows = <Map<String, String>>[];
  var offenders = 0;
  for (final path in files) {
    try {
      final txt = File(path).readAsStringSync();
      final idx = _firstNonAsciiIndex(txt);
      if (idx != -1) {
        offenders++;
        final cp = txt.codeUnitAt(idx);
        rows.add({
          'file': path,
          'codepoint': _codepoint(cp),
          'sample': _asciiSample(txt, idx),
        });
      }
    } catch (_) {
      // Ignore I/O errors; keep tool resilient
    }
  }
  rows.sort((a, b) => a['file']!.compareTo(b['file']!));

  final out = {
    'rows': rows,
    'summary': {'files': files.length, 'offenders': offenders},
  };

  final payload = jsonEncode(out);
  if (jsonPath != null && jsonPath!.isNotEmpty) {
    try {
      File(jsonPath!).writeAsStringSync(payload);
    } catch (_) {
      // best-effort
    }
  }
  if (!quiet) {
    stdout.writeln(payload);
  }
}

List<String> _collectFiles(String? only) {
  final root = Directory('content');
  final out = <String>[];
  if (!root.existsSync()) return out;
  final mods = <String>[];
  for (final e in root.listSync()) {
    if (e is! Directory) continue;
    final id = _basename(e.path);
    if (id.isEmpty || id.startsWith('_')) continue;
    if (only != null && id != only) continue;
    final v1 = Directory('${e.path}/v1');
    if (v1.existsSync()) mods.add(id);
  }
  mods.sort();
  for (final m in mods) {
    final base = 'content/$m/v1';
    for (final name in ['theory.md', 'demos.jsonl', 'drills.jsonl']) {
      final p = '$base/$name';
      if (File(p).existsSync()) out.add(p);
    }
  }
  out.sort();
  return out;
}

int _firstNonAsciiIndex(String s) {
  for (var i = 0; i < s.length; i++) {
    if (s.codeUnitAt(i) > 0x7F) return i;
  }
  return -1;
}

String _codepoint(int codeUnit) {
  final hex = codeUnit.toRadixString(16).toUpperCase().padLeft(4, '0');
  return 'U+' + hex;
}

String _asciiSample(String s, int idx) {
  final start = idx - 12 < 0 ? 0 : idx - 12;
  var end = idx + 12;
  if (end > s.length) end = s.length;
  final frag = s.substring(start, end);
  final b = StringBuffer();
  for (final cu in frag.codeUnits) {
    if (cu >= 32 && cu <= 126) {
      b.writeCharCode(cu);
    } else {
      b.write('?');
    }
  }
  return b.toString();
}

String _basename(String path) {
  final norm = path.replaceAll('\\', '/');
  var s = norm;
  if (s.endsWith('/')) s = s.substring(0, s.length - 1);
  final idx = s.lastIndexOf('/');
  return idx == -1 ? s : s.substring(idx + 1);
}
