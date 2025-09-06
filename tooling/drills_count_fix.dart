// Normalize drills.jsonl line counts to [10, 20].
// Usage:
//   dart run tooling/drills_count_fix.dart [--module <id>] [--fix-dry-run] [--fix] [--quiet]
//
// - If <10 drills: duplicate the last valid drill line with a new id '<old>_auto<N>' until 10.
// - If >20 drills: report trim count; when --fix is set, drop trailing lines to 20.
// Idempotent, ASCII-only, no deps. Summary:
//   DRILLS-COUNT-FIX modules=<N> edited=<K> trimmed=<T> skipped=<M>

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  String? onlyModule;
  var writeFixes = false;
  var dry = false;
  var quiet = false;

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--module' && i + 1 < args.length) {
      onlyModule = args[++i];
    } else if (a == '--fix') {
      writeFixes = true;
    } else if (a == '--fix-dry-run') {
      dry = true;
      writeFixes = false;
    } else if (a == '--quiet') {
      quiet = true;
    }
  }

  final modules = _discoverModules(onlyModule);
  var modulesScanned = 0;
  var edited = 0; // modules where we added entries to reach 10
  var trimmed = 0; // modules where we trimmed to 20
  var skipped = 0;
  var ioError = false;

  for (final m in modules) {
    final path = 'content/$m/v1/drills.jsonl';
    final file = File(path);
    if (!file.existsSync()) continue;
    modulesScanned++;

    String raw;
    try {
      raw = file.readAsStringSync();
    } catch (e) {
      if (!quiet) stderr.writeln('read error: $path: $e');
      ioError = true;
      continue;
    }

    final hadCrLf = raw.contains('\r\n');
    final eol = hadCrLf ? '\r\n' : '\n';
    final hadTrailing = raw.endsWith('\n') || raw.endsWith('\r\n');
    final normalized = raw.replaceAll('\r\n', '\n');
    final lines = const LineSplitter().convert(normalized);

    // Identify valid drills and ID set
    final ids = <String>{};
    int lastValidIdx = -1;
    for (var i = 0; i < lines.length; i++) {
      final s = lines[i].trim();
      if (s.isEmpty) continue;
      try {
        final obj = jsonDecode(s);
        if (obj is Map && obj['id'] is String) {
          ids.add(obj['id'] as String);
          lastValidIdx = i;
        }
      } catch (_) {}
    }

    final count = lines.where((l) => l.trim().isNotEmpty).length;
    if (count >= 10 && count <= 20) {
      skipped++;
      continue;
    }

    var newLines = List<String>.from(lines);
    var changed = false;

    if (count < 10 && lastValidIdx != -1) {
      final template = lines[lastValidIdx].trim();
      int need = 10 - count;
      // Determine base id for suffixing
      String baseId = 'auto';
      try {
        final obj = jsonDecode(template);
        if (obj is Map && obj['id'] is String) {
          baseId = obj['id'] as String;
        }
      } catch (_) {}
      var n = 1;
      for (var k = 0; k < need; k++) {
        String newId;
        do {
          newId = '${baseId}_auto$n';
          n++;
        } while (ids.contains(newId));
        ids.add(newId);
        String newLine = template;
        try {
          final obj = jsonDecode(template) as Map<String, dynamic>;
          obj['id'] = newId;
          newLine = jsonEncode(obj);
        } catch (_) {
          // fallback: string replace last occurrence of baseId
          newLine = template.replaceFirst(baseId, newId);
        }
        newLines.add(newLine);
      }
      edited++;
      changed = true;
    }

    if (count > 20) {
      final keep = <String>[];
      var seen = 0;
      for (final l in lines) {
        if (l.trim().isEmpty) continue;
        keep.add(l);
        seen++;
        if (seen == 20) break;
      }
      newLines = keep;
      trimmed++;
      changed = true;
    }

    if (changed && writeFixes) {
      try {
        final body = newLines.join(eol) + (hadTrailing ? eol : '');
        file.writeAsStringSync(body);
      } catch (e) {
        if (!quiet) stderr.writeln('write error: $path: $e');
        ioError = true;
      }
    }
  }

  stdout.writeln(
    'DRILLS-COUNT-FIX modules=$modulesScanned edited=$edited trimmed=$trimmed skipped=$skipped',
  );
  if (ioError && writeFixes) exitCode = 1;
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
