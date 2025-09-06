// Normalize demos.jsonl counts to 2–3 items per module.
// Usage:
//   dart run tooling/demos_count_fix.dart [--module <id>] [--fix-dry-run] [--fix] [--quiet]
//
// Rules:
// - Ignore blank lines and comment lines starting with // or #.
// - If >3 demos -> keep first 3, drop the rest.
// - If <2 demos -> append placeholder demos until 2.
// Placeholders:
//   id: auto_demo_<n>
//   spot_kind: first entry from tooling/allowlists/spotkind_allowlist_<module>.txt if present and not 'none', else 'none'
//   tokens: ["call"]
//   steps: 4 strings; the last contains '(auto)'.
//
// Summary:
//   DEMO-COUNT-FIX modules=<N> edited=<K> trimmed=<T> filled=<F> skipped=<M>
// Exit 0 unless I/O error during writes (dry-run always 0). ASCII-only, idempotent.

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
  var edited = 0;
  var trimmed = 0;
  var filled = 0;
  var skipped = 0;
  var ioError = false;

  for (final m in modules) {
    final dir = Directory('content/$m/v1');
    if (!dir.existsSync()) continue;
    modulesScanned++;
    final path = '${dir.path}/demos.jsonl';
    final file = File(path);

    String raw = '';
    if (file.existsSync()) {
      try {
        raw = file.readAsStringSync();
      } catch (e) {
        if (!quiet) stderr.writeln('read error: $path: $e');
        ioError = true;
        continue;
      }
    }

    final hadCrLf = raw.contains('\r\n');
    final eol = hadCrLf ? '\r\n' : '\n';
    final hadTrailing = raw.endsWith('\n') || raw.endsWith('\r\n');
    final normalized = raw.replaceAll('\r\n', '\n');
    final lines = raw.isEmpty
        ? <String>[]
        : const LineSplitter().convert(normalized);

    // Parse demos ignoring comments/blank lines
    final keptRaw = <String>[]; // keep original text of the first 3 valid demos
    final othersRaw = <String>[];
    var hasComments = false;
    for (final l in lines) {
      final t = l.trim();
      if (t.isEmpty) continue;
      if (t.startsWith('//') || t.startsWith('#')) {
        hasComments = true; // drop comments in rewritten output
        continue;
      }
      // Ensure it's valid JSON object line
      try {
        final v = jsonDecode(t);
        if (v is Map) {
          if (keptRaw.length < 3) {
            keptRaw.add(jsonEncode(v));
          } else {
            othersRaw.add(jsonEncode(v));
          }
        }
      } catch (_) {
        // ignore unparsable lines
      }
    }

    var changed = false;
    var didTrim = false;
    var didFill = false;

    // Trim if more than 3 valid
    if (othersRaw.isNotEmpty) {
      didTrim = true;
      changed = true;
    }

    // Fill if fewer than 2 valid
    if (keptRaw.length < 2) {
      final needed = 2 - keptRaw.length;
      final spotKind = _firstAllowSpotKind(m) ?? 'none';
      // Build unique IDs avoiding collisions with existing ids
      final existingIds = <String>{};
      for (final r in keptRaw) {
        try {
          final obj = jsonDecode(r);
          if (obj is Map && obj['id'] is String)
            existingIds.add(obj['id'] as String);
        } catch (_) {}
      }
      var n = 1;
      for (var i = 0; i < needed; i++) {
        String id;
        do {
          id = 'auto_demo_${n++}';
        } while (existingIds.contains(id));
        existingIds.add(id);
        final obj = {
          'id': id,
          'spot_kind': spotKind,
          'tokens': ['call'],
          'steps': [
            'Context: placeholder auto demo for scaffolding',
            'Decision framing in fixed families 33/50/75',
            'Rule: keep actions inside token set',
            'Step 4 - Wrap-up: key takeaway (auto)',
          ],
        };
        keptRaw.add(jsonEncode(obj));
        didFill = true;
        changed = true;
      }
    }

    // If counts are OK (2-3) but file contains comments, rewrite to a clean 2-3 JSON lines
    if (!changed && hasComments && keptRaw.length >= 2 && keptRaw.length <= 3) {
      changed = true;
    }

    if (!changed) {
      skipped++;
      continue;
    }

    // Compose new file body with exactly keptRaw (<=3, >=2 guaranteed if we filled)
    final newBody = keptRaw.join(eol) + eol;
    if (writeFixes) {
      try {
        // Ensure directory exists
        dir.createSync(recursive: true);
        file.writeAsStringSync(newBody);
      } catch (e) {
        if (!quiet) stderr.writeln('write error: $path: $e');
        ioError = true;
        continue;
      }
    }
    if (didTrim) trimmed++;
    if (didFill) filled++;
    edited++;
  }

  stdout.writeln(
    'DEMO-COUNT-FIX modules=$modulesScanned edited=$edited trimmed=$trimmed filled=$filled skipped=$skipped',
  );
  if (ioError && !dry && writeFixes) exitCode = 1;
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
