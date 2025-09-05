// Sanitize punctuation/whitespace in content to pure ASCII.
// Usage:
//   dart run tooling/ascii_sanitize.dart [--module <id>] [--fix-dry-run] [--fix] [--check] [--quiet]
//
// Scope: content/*/v1/{theory.md,demos.jsonl,drills.jsonl}
// Changes are deterministic and idempotent. Only punctuation/whitespace is touched:
// - Curly quotes to ' and "
// - En/em/minus dashes to '-'
// - Ellipsis to '...'
// - NBSP/zero-width spaces to ' '
// - Fancy bullets to '-'
// - Common math signs: ≤ -> <=, ≥ -> >=, ≠ -> !=, ± -> +/-, × -> x, ÷ -> /
// - Normalize CRLF/CR to LF; strip BOM
//
// Output one line: ASCII-SANITIZE files=<n> fixed=<k> unchanged=<m>
// Exit 0 unless I/O error.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  String? onlyModule;
  var fix = false;
  var dry = false;
  var check = false;
  var quiet = false;

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--module' && i + 1 < args.length) {
      onlyModule = args[++i];
    } else if (a == '--fix') {
      fix = true;
    } else if (a == '--fix-dry-run') {
      dry = true;
    } else if (a == '--check') {
      check = true;
      dry = true; // behave like dry-run: no writes
      fix = false; // ensure no writes
    } else if (a == '--quiet') {
      quiet = true;
    }
  }

  final modules = _discoverModules(onlyModule);
  final files = <String>[];
  for (final m in modules) {
    final base = 'content/$m/v1';
    for (final name in ['theory.md', 'demos.jsonl', 'drills.jsonl']) {
      final p = '$base/$name';
      if (File(p).existsSync()) files.add(p);
    }
  }

  var fixed = 0;
  var unchanged = 0;
  var ioError = false;

  for (final path in files) {
    String raw;
    try {
      raw = File(path).readAsStringSync();
    } catch (e) {
      if (!quiet) stderr.writeln('read error: $path: $e');
      ioError = true;
      continue;
    }
    final res = _sanitize(raw);
    if (res.changes > 0) {
      if (dry && !quiet) {
        stdout.writeln('$path: +${res.changes}');
      }
      if (fix && res.text != raw) {
        try {
          File(path).writeAsStringSync(res.text);
        } catch (e) {
          if (!quiet) stderr.writeln('write error: $path: $e');
          ioError = true;
          continue;
        }
      }
      fixed++;
    } else {
      unchanged++;
    }
  }

  final suffix = check ? ' (check)' : '';
  stdout.writeln(
    'ASCII-SANITIZE files=${files.length} fixed=$fixed unchanged=$unchanged$suffix',
  );
  if (ioError) {
    exitCode = 1;
  } else if (check && fixed > 0) {
    // Fail in check mode if any file would be changed
    exitCode = 1;
  }
}

class _SanRes {
  final String text;
  final int changes;
  _SanRes(this.text, this.changes);
}

_SanRes _sanitize(String s) {
  var text = s;
  var changes = 0;

  // Strip BOM
  if (text.isNotEmpty && text.codeUnitAt(0) == 0xFEFF) {
    text = text.substring(1);
    changes++;
  }
  // Normalize line endings to LF
  final beforeLen = text.length;
  text = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  if (text.length != beforeLen) changes++;

  String replChar(String input, String from, String to) {
    final count = _countOf(input, from);
    if (count > 0) changes += count;
    return input.replaceAll(from, to);
  }

  // Single-char replacements
  final singles = <String, String>{
    // curly single quotes → '
    '\u2018': "'",
    '\u2019': "'",
    '\u2032': "'", // prime
    // curly double quotes → "
    '\u201C': '"',
    '\u201D': '"',
    '\u2033': '"',
    // dashes/minus → -
    '\u2013': '-', // en dash
    '\u2014': '-', // em dash
    '\u2212': '-', // minus sign
    // ellipsis → ...
    '\u2026': '...',
    // spaces/zero-width
    '\u00A0': ' ', // NBSP
    '\u2007': ' ', // figure space
    '\u2009': ' ', // thin space
    '\u200B': ' ', // zero-width space -> space
    '\u200C': ' ', // zero-width non-joiner -> space
    '\u200D': ' ', // zero-width joiner -> space
    '\u2060': ' ', // word joiner
    // bullets → -
    '\u2022': '-',
    '\u25CF': '-',
    '\u2219': '-',
    // math signs
    '\u2260': '!=',
    '\u2264': '<=',
    '\u2265': '>=',
    '\u00B1': '+/-',
    '\u00D7': 'x',
    '\u00F7': '/',
  };
  singles.forEach((from, to) {
    text = replChar(text, from, to);
  });

  // Collapse multiple spaces introduced by replacements (optional; conservative)
  // Keep tabs/newlines; only normalize runs of >1 spaces to single space.
  final spaceRuns = RegExp(r' {2,}');
  final runMatches = spaceRuns.allMatches(text).length;
  if (runMatches > 0) changes += runMatches;
  text = text.replaceAll(spaceRuns, ' ');

  return _SanRes(text, changes);
}

int _countOf(String s, String sub) {
  if (sub.isEmpty) return 0;
  var count = 0;
  var idx = 0;
  while (true) {
    idx = s.indexOf(sub, idx);
    if (idx == -1) break;
    count++;
    idx += sub.length;
  }
  return count;
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
