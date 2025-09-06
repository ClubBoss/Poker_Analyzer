// Repair lightly malformed JSON lines in drills.jsonl files.
// Usage:
//   dart run tooling/drills_json_repair.dart [--module <id>] [--fix-dry-run] [--fix] [--quiet]
//
// Scope: content/*/v1/drills.jsonl
// For each non-empty, non-comment line, try jsonDecode. If it fails, attempt minimal repairs:
// - Replace common smart quotes and Unicode spaces with ASCII equivalents
// - Drop trailing commas before '}' or ']'
// - Escape unescaped double quotes inside string values when they likely aren't closing quotes
// - Normalize line endings (handled by reading logic)
// Re-parse; if still failing, leave the line unchanged and count as error.
// Output: DRILLS-JSON-REPAIR modules=<N> fixed=<K> errors=<E> skipped=<M>
// Idempotent and deterministic. ASCII-only. No external deps.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  String? onlyModule;
  bool writeFixes = false;
  bool dry = false;
  bool quiet = false;

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
  var fixed = 0;
  var errors = 0;
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

    final normalized = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = const LineSplitter().convert(normalized);
    final outLines = <String>[];
    var changed = false;

    for (final line in lines) {
      final t = line.trim();
      if (t.isEmpty || t.startsWith('//') || t.startsWith('#')) {
        outLines.add(line);
        continue;
      }
      // First try parse
      if (_canParse(t)) {
        outLines.add(line);
        continue;
      }
      // Attempt repairs
      var repaired = _asciiReplace(t);
      repaired = _dropTrailingCommas(repaired);
      repaired = _escapeInnerQuotes(repaired);

      if (_canParse(repaired)) {
        outLines.add(repaired);
        fixed++;
        changed = true;
      } else {
        outLines.add(line); // keep original
        errors++;
      }
    }

    if (changed && writeFixes && !dry) {
      try {
        // Preserve trailing newline if present in original
        final hadTrailing = raw.endsWith('\n') || raw.endsWith('\r\n');
        final eol = raw.contains('\r\n') ? '\r\n' : '\n';
        final body = outLines.join(eol) + (hadTrailing ? eol : '');
        file.writeAsStringSync(body);
      } catch (e) {
        if (!quiet) stderr.writeln('write error: $path: $e');
        ioError = true;
      }
    } else if (!changed) {
      skipped++;
    }
  }

  stdout.writeln(
    'DRILLS-JSON-REPAIR modules=$modulesScanned fixed=$fixed errors=$errors skipped=$skipped',
  );
  if (ioError && writeFixes) exitCode = 1;
}

bool _canParse(String s) {
  try {
    final v = jsonDecode(s);
    return v is Map || v is List;
  } catch (_) {
    return false;
  }
}

String _asciiReplace(String s) {
  var text = s;
  // common unicode quotes/dashes/spaces
  const map = {
    '\u2018': "'",
    '\u2019': "'",
    '\u2032': "'",
    '\u201C': '"',
    '\u201D': '"',
    '\u2033': '"',
    '\u2013': '-',
    '\u2014': '-',
    '\u2212': '-',
    '\u2026': '...',
    '\u00A0': ' ',
    '\u2007': ' ',
    '\u2009': ' ',
    '\u200B': ' ',
    '\u200C': ' ',
    '\u200D': ' ',
    '\u2060': ' ',
  };
  map.forEach((k, v) => text = text.replaceAll(k, v));
  return text;
}

String _dropTrailingCommas(String s) {
  final b = StringBuffer();
  var inside = false;
  var escaped = false;
  for (var i = 0; i < s.length; i++) {
    final c = s[i];
    if (c == '"' && !escaped) {
      inside = !inside;
      b.write(c);
      continue;
    }
    if (!inside && c == ',') {
      // Lookahead to next non-space
      var j = i + 1;
      while (j < s.length &&
          (s[j] == ' ' || s[j] == '\t' || s[j] == '\n' || s[j] == '\r'))
        j++;
      if (j < s.length && (s[j] == '}' || s[j] == ']')) {
        // skip this comma
        continue;
      }
    }
    if (c == '\\' && !escaped) {
      escaped = true;
    } else {
      escaped = false;
    }
    b.write(c);
  }
  return b.toString();
}

String _escapeInnerQuotes(String s) {
  final b = StringBuffer();
  var inside = false;
  var escaped = false;
  for (var i = 0; i < s.length; i++) {
    final c = s[i];
    if (c == '"' && !escaped) {
      if (!inside) {
        inside = true;
        b.write(c);
      } else {
        // Potentially closing; check next non-space
        var j = i + 1;
        while (j < s.length && (s[j] == ' ' || s[j] == '\t')) j++;
        if (j >= s.length || s[j] == ',' || s[j] == '}' || s[j] == ']') {
          // Treat as closing
          inside = false;
          b.write(c);
        } else {
          // Likely an inner unescaped quote inside value -> escape it
          b.write('\\"');
        }
      }
      escaped = false;
      continue;
    }
    if (c == '\\' && !escaped) {
      escaped = true;
    } else {
      escaped = false;
    }
    b.write(c);
  }
  return b.toString();
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
