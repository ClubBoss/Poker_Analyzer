// Demos steps fixer: auto-append a safe 4th step.
// Usage:
//   dart run tooling/demos_steps_fix.dart [--module <id>] [--fix-dry-run] [--fix] [--quiet]
//
// Scope: content/*/v1/demos.jsonl
// For each demo with steps length < 4, append one deterministic step.
// - If steps is an array of strings -> append a string
// - If steps is an array of objects -> append {"type":"text","value":<string>}
// Idempotent: if any existing step contains the exact substring "(auto)", skip.
// Preserve line order; only modified lines are re-serialized (spacing preserved elsewhere).
// Output one-liner: DEMO-STEPS-FIX modules=<N> edited=<K> skipped=<M>.
// Exit 0 unless I/O error (dry-run always 0).

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  String? onlyModule;
  var writeFixes = false; // default dry-run
  var quiet = false;

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--module' && i + 1 < args.length) {
      onlyModule = args[++i];
    } else if (a == '--fix') {
      writeFixes = true;
    } else if (a == '--fix-dry-run') {
      // explicit dry-run; no writes
      writeFixes = false;
    } else if (a == '--quiet') {
      quiet = true;
    }
  }

  final modules = _discoverModules(onlyModule);
  var modulesScanned = 0;
  var edited = 0;
  var skipped = 0;
  var ioError = false;

  for (final m in modules) {
    final path = 'content/$m/v1/demos.jsonl';
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

    var changed = false;
    final outLines = <String>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        outLines.add(line);
        continue;
      }
      dynamic obj;
      try {
        obj = jsonDecode(trimmed);
      } catch (_) {
        // Unparsable line: keep as-is
        outLines.add(line);
        skipped++;
        continue;
      }
      if (obj is! Map<String, dynamic>) {
        outLines.add(line);
        skipped++;
        continue;
      }

      final stepsDyn = obj['steps'];
      if (stepsDyn is! List) {
        outLines.add(line);
        skipped++;
        continue;
      }

      // Detect idempotence: any step containing "(auto)" -> skip
      var hasAuto = false;
      for (final s in stepsDyn) {
        if (s is String && s.contains('(auto)')) {
          hasAuto = true;
          break;
        }
        if (s is Map) {
          final v = s['value'];
          final t = s['text'];
          if (v is String && v.contains('(auto)')) {
            hasAuto = true;
            break;
          }
          if (t is String && t.contains('(auto)')) {
            hasAuto = true;
            break;
          }
        }
      }

      // Idempotence rule: if already 4+ steps, skip.
      // If fewer than 4 steps, we still append even if an (auto) line exists
      // to bring the demo to a minimum of 4 steps.
      if (stepsDyn.length >= 4) {
        outLines.add(line);
        skipped++;
        continue;
      }

      // Decide style based on first element when present; default to string style.
      final appendText = 'Step 4 - Wrap-up: key takeaway (auto)';
      if (stepsDyn.isNotEmpty && stepsDyn.first is Map) {
        final first = stepsDyn.first as Map;
        if (first.containsKey('text')) {
          stepsDyn.add({'text': appendText});
        } else {
          // default to value + type to match prior convention
          stepsDyn.add({'type': 'text', 'value': appendText});
        }
      } else {
        stepsDyn.add(appendText);
      }
      obj['steps'] = stepsDyn;

      final newLine = jsonEncode(obj);
      if (newLine != line) changed = true;
      outLines.add(newLine);
      edited++;
    }

    if (writeFixes && changed) {
      try {
        final body = outLines.join(eol) + (hadTrailing ? eol : '');
        file.writeAsStringSync(body);
      } catch (e) {
        if (!quiet) stderr.writeln('write error: $path: $e');
        ioError = true;
      }
    }
  }

  stdout.writeln(
    'DEMO-STEPS-FIX modules=$modulesScanned edited=$edited skipped=$skipped.',
  );
  if (ioError && writeFixes) exitCode = 1; // dry-run always 0
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
