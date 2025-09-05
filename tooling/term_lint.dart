// Terminology linter for content files.
// Usage:
//   dart run tooling/term_lint.dart
//   dart run tooling/term_lint.dart --module <id>
//   dart run tooling/term_lint.dart --json <path>
//   dart run tooling/term_lint.dart --quiet
//
// Scans content/*/v1/{theory.md,demos.jsonl,drills.jsonl} and flags:
// - Narrative terms: prefer token 'probe_turns' over 'lead/donk/donkbet'.
// - Casing for Fv50/Fv75: only exact 'Fv50' and 'Fv75' allowed.
//
// Output: stable ASCII table per module
//   module|bad_terms|fv_bad_case|files_with_issues
// and returns exit code 1 if any issues are found (else 0).

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  String? filter;
  String? jsonPath;
  var quiet = false;
  var doFix = false;
  var dryFix = false;
  var fixScope = 'md'; // md | md+jsonl

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--quiet') {
      quiet = true;
    } else if (a == '--json') {
      if (i + 1 < args.length) jsonPath = args[++i];
    } else if (a == '--module' && i + 1 < args.length) {
      filter = args[++i];
    } else if (a == '--fix') {
      doFix = true;
    } else if (a == '--fix-dry-run') {
      dryFix = true;
    } else if (a.startsWith('--fix-scope=')) {
      final v = a.substring('--fix-scope='.length);
      if (v == 'md' || v == 'md+jsonl') fixScope = v;
    } else if (!a.startsWith('--') && a != 'all' && filter == null) {
      // Back-compat single positional module id
      filter = a;
    }
  }

  final modules = _discoverModules(filter);

  // Apply fixes if requested (deterministic ordering)
  var ioError = false;
  if (doFix || dryFix) {
    for (final m in modules) {
      final base = 'content/$m/v1';
      final toProcess = <String>['theory.md'];
      if (fixScope == 'md+jsonl') {
        toProcess.addAll(['demos.jsonl', 'drills.jsonl']);
      }
      for (final name in toProcess) {
        final path = '$base/$name';
        final f = File(path);
        if (!f.existsSync()) continue;
        try {
          if (name.endsWith('.md')) {
            final res = _fixMarkdownLines(f.readAsLinesSync());
            if (res.replacements > 0) {
              final tag = dryFix ? 'DRY' : 'FIX';
              stdout.writeln('$tag $path: +${res.replacements}');
              if (!dryFix) f.writeAsStringSync(res.newLines.join('\n'));
            }
          } else {
            final res = _fixJsonlLines(f.readAsLinesSync());
            if (res.replacements > 0) {
              final tag = dryFix ? 'DRY' : 'FIX';
              stdout.writeln('$tag $path: +${res.replacements}');
              if (!dryFix) f.writeAsStringSync(res.newLines.join('\n'));
            }
          }
        } catch (e) {
          stderr.writeln('fix error: $path: $e');
          ioError = true;
        }
      }
    }
  }

  // Lint current state
  final rows = <_Row>[];
  var anyIssues = false;
  for (final m in modules) {
    final report = _lintModule(
      m,
      quiet: quiet || (doFix && quiet) || (dryFix && quiet),
    );
    rows.add(report);
    if (report.badTerms > 0 || report.fvBadCase > 0) anyIssues = true;
  }

  // Optional JSON
  if (jsonPath != null) {
    final payload = <String, dynamic>{
      'rows': rows
          .map(
            (r) => {
              'module': r.module,
              'bad_terms': r.badTerms,
              'fv_bad_case': r.fvBadCase,
              'files_with_issues': r.filesWithIssues.toList(),
            },
          )
          .toList(),
      'totals': {
        'bad_terms': rows.fold<int>(0, (a, b) => a + b.badTerms),
        'fv_bad_case': rows.fold<int>(0, (a, b) => a + b.fvBadCase),
      },
    };
    try {
      final f = File(jsonPath);
      f.parent.createSync(recursive: true);
      f.writeAsStringSync(jsonEncode(payload));
    } catch (e) {
      stderr.writeln('write error: $e');
      exitCode = 1;
      return;
    }
  }

  if (!quiet) {
    _printTable(rows);
  }

  if (dryFix) return; // always success
  if (doFix) {
    if (ioError) exitCode = 1;
    return;
  }

  if (anyIssues) exitCode = 1;
}

class _Row {
  final String module;
  final int badTerms;
  final int fvBadCase;
  final List<String> filesWithIssues;
  _Row({
    required this.module,
    required this.badTerms,
    required this.fvBadCase,
    required this.filesWithIssues,
  });
}

void _printTable(List<_Row> rows) {
  stdout.writeln('module|bad_terms|fv_bad_case|files_with_issues');
  for (final r in rows) {
    final files = r.filesWithIssues.isEmpty
        ? '-'
        : r.filesWithIssues.take(5).join(',');
    stdout.writeln('${r.module}|${r.badTerms}|${r.fvBadCase}|$files');
  }
}

_Row _lintModule(String moduleId, {required bool quiet}) {
  final base = 'content/$moduleId/v1';
  final files = <String>['theory.md', 'demos.jsonl', 'drills.jsonl'];
  var badTerms = 0;
  var fvBadCase = 0;
  final touched = <String>[];

  for (final name in files) {
    final path = '$base/$name';
    final f = File(path);
    if (!f.existsSync()) continue;
    List<String> lines;
    try {
      lines = f.readAsLinesSync();
    } catch (e) {
      stderr.writeln('read error: $path: $e');
      continue;
    }

    var localBad = 0;
    var localFv = 0;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      // Rule 1: Narrative terms -> prefer probe_turns
      final r1 = RegExp(
        r'\b(donkbet|donk|lead|leads|leading)\b',
        caseSensitive: false,
      );
      for (final m in r1.allMatches(line)) {
        localBad++;
        if (!quiet) {
          final term = m.group(0);
          stderr.writeln(
            '$path:${i + 1}: prefer token "probe_turns" over "$term"',
          );
        }
      }

      // Rule 2: Fv50/Fv75 casing
      final r2 = RegExp(r'\b[fF][vV][\s\-_]?(50|75)\b');
      for (final m in r2.allMatches(line)) {
        final raw = m.group(0)!;
        if (raw == 'Fv50' || raw == 'Fv75') {
          continue; // OK
        }
        localFv++;
        if (!quiet) {
          final target = raw.contains('50') ? 'Fv50' : 'Fv75';
          stderr.writeln(
            '$path:${i + 1}: use exact "$target" (casing and no spaces)',
          );
        }
      }
    }

    if (localBad > 0 || localFv > 0) {
      touched.add(name);
      badTerms += localBad;
      fvBadCase += localFv;
    }
  }

  // Sort filenames deterministically
  touched.sort();
  return _Row(
    module: moduleId,
    badTerms: badTerms,
    fvBadCase: fvBadCase,
    filesWithIssues: touched,
  );
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

class _FixResult {
  final List<String> newLines;
  final int replacements;
  _FixResult(this.newLines, this.replacements);
}

_FixResult _fixMarkdownLines(List<String> lines) {
  final out = <String>[];
  var count = 0;
  for (final line in lines) {
    final r = _applyFixesToString(line);
    out.add(r.item1);
    count += r.item2;
  }
  return _FixResult(out, count);
}

_FixResult _fixJsonlLines(List<String> lines) {
  final out = <String>[];
  var count = 0;
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      out.add(line);
      continue;
    }
    try {
      final obj = jsonDecode(line);
      if (obj is Map<String, dynamic>) {
        var local = 0;
        final steps = obj['steps'];
        if (steps is List) {
          for (var i = 0; i < steps.length; i++) {
            final v = steps[i];
            if (v is String) {
              final r = _applyFixesToString(v);
              if (r.item2 > 0) {
                steps[i] = r.item1;
                local += r.item2;
              }
            }
          }
        }
        // Allowed string fields for safe in-place normalization.
        // Never touch: id, spot_kind|spotKind, target|targets, or non-string values.
        for (final k in [
          'title',
          'caption',
          'question',
          'answer',
          'hint',
          'rationale',
          'text',
          'note',
          'explanation',
          'prompt',
        ]) {
          final v = obj[k];
          if (v is String) {
            final r = _applyFixesToString(v);
            if (r.item2 > 0) {
              obj[k] = r.item1;
              local += r.item2;
            }
          }
        }
        if (local > 0) {
          out.add(jsonEncode(obj));
          count += local;
        } else {
          out.add(line);
        }
      } else {
        out.add(line);
      }
    } catch (_) {
      out.add(line);
    }
  }
  return _FixResult(out, count);
}

// Tuple-like return for string fixes
class _S2 {
  final String item1;
  final int item2;
  _S2(this.item1, this.item2);
}

_S2 _applyFixesToString(String s) {
  var text = s;
  var count = 0;
  // Rule 1: narrative donk/lead -> probe_turns (case-insensitive)
  final r1 = RegExp(
    r'\b(donkbet|donk|lead|leads|leading)\b',
    caseSensitive: false,
  );
  text = text.replaceAllMapped(r1, (m) {
    count++;
    return 'probe_turns';
  });
  // Rule 2: Fv50/Fv75 casing normalization
  final r2 = RegExp(r'\b[fF][vV][\s\-_]?(50|75)\b');
  text = text.replaceAllMapped(r2, (m) {
    final raw = m.group(0)!;
    final d = m.group(1)!;
    if (raw == 'Fv$d') return raw;
    count++;
    return 'Fv$d';
  });
  return _S2(text, count);
}
