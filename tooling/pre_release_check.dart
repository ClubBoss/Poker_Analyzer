// Pre-release aggregator: runs content gates and prints a PASS/FAIL summary.
// Usage: dart run tooling/pre_release_check.dart
// Pure Dart. ASCII-only. No external deps.

import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  // Ensure build directory exists
  final buildDir = Directory('build');
  if (!buildDir.existsSync()) buildDir.createSync(recursive: true);

  // 0) ASCII gate (fail-fast signal folded into OVERALL)
  final asc = await _runSilent([
    'dart',
    'run',
    'tooling/ascii_sanitize.dart',
    '--check',
  ]);
  final asciiOk = asc.exitCode == 0;

  // 1) GAP report (JSON)
  await _runSilent([
    'dart',
    'run',
    'tooling/content_gap_report.dart',
    '--json',
    'build/gaps.json',
  ]);

  // 2) Terminology lint (JSON, quiet)
  await _runSilent([
    'dart',
    'run',
    'tooling/term_lint.dart',
    '--json',
    'build/term_lint.json',
    '--quiet',
  ]);

  // 3) Validate progression (capture exit code)
  final prog = await _runSilent([
    'dart',
    'run',
    'tooling/validate_progression.dart',
  ]);
  final progressionOk = prog.exitCode == 0;

  // 4) Compute unlocks (write to file)
  final unlocks = await _runSilent([
    'dart',
    'run',
    'tooling/compute_unlocks.dart',
  ]);
  File('build/unlocks.txt').writeAsStringSync(unlocks.stdout);

  // 5) Export badges (JSON)
  await _runSilent([
    'dart',
    'run',
    'tooling/export_progression_badges.dart',
    '--json',
    'build/badges.json',
  ]);

  // Discovery chain (non-gating here)
  await _runSilent([
    'dart',
    'run',
    'tooling/build_search_index.dart',
    '--json',
    'build/search_index.json',
  ]);
  await _runSilent([
    'dart',
    'run',
    'tooling/build_see_also.dart',
    '--json',
    'build/see_also.json',
  ]);
  await _runSilent(['dart', 'run', 'tooling/link_see_also_in_theory.dart']);
  await _runSilent([
    'dart',
    'run',
    'tooling/export_ui_assets.dart',
    '--out',
    'build/ui_assets',
  ]);

  // Images gate (silent). Fold into overall.
  final img = await _runSilent(['dart', 'run', 'tooling/validate_images.dart']);
  final imagesOk = _imagesOk(img.stdout);

  // Parse produced artifacts
  final gapsOk = _gapsOk('build/gaps.json');
  final termsOk = _termsOk('build/term_lint.json');

  final overallOk = gapsOk && termsOk && progressionOk && imagesOk && asciiOk;

  final lines = <String>[
    'PRE-RELEASE',
    'GAPS OK ${gapsOk ? 1 : 0}',
    'TERMS OK ${termsOk ? 1 : 0}',
    'PROGRESSION OK ${progressionOk ? 1 : 0}',
    'OVERALL OK ${overallOk ? 1 : 0}',
    'ARTIFACTS build/gaps.json,build/term_lint.json,build/unlocks.txt,build/badges.json,build/search_index.json,build/see_also.json,build/ui_assets/manifest.json',
  ];

  for (final l in lines) stdout.writeln(l);
  File(
    'build/pre_release_check.txt',
  ).writeAsStringSync(lines.join('\n') + '\n');

  if (!overallOk) exitCode = 1;
}

Future<_RunResult> _runSilent(List<String> cmd) async {
  try {
    final p = await Process.run(cmd.first, cmd.sublist(1));
    // Do not forward stdout/stderr; keep steps quiet.
    return _RunResult(p.exitCode, (p.stdout ?? '').toString());
  } catch (e) {
    return _RunResult(1, '');
  }
}

class _RunResult {
  final int exitCode;
  final String stdout;
  _RunResult(this.exitCode, this.stdout);
}

bool _gapsOk(String path) {
  final f = File(path);
  if (!f.existsSync()) return false;
  try {
    final obj = jsonDecode(f.readAsStringSync());
    if (obj is! Map<String, dynamic>) return false;
    final totals = obj['totals'];
    if (totals is! Map) return false;
    for (final v in (totals).values) {
      if (v is int) {
        if (v != 0) return false;
      }
    }
    return true;
  } catch (_) {
    return false;
  }
}

bool _termsOk(String path) {
  final f = File(path);
  if (!f.existsSync()) return false;
  try {
    final obj = jsonDecode(f.readAsStringSync());
    if (obj is! Map<String, dynamic>) return false;
    final totals = obj['totals'];
    if (totals is! Map) return false;
    final bt = (totals)['bad_terms'];
    final fv = (totals)['fv_bad_case'];
    if (bt is int && fv is int) {
      return bt == 0 && fv == 0;
    }
    return false;
  } catch (_) {
    return false;
  }
}

bool _imagesOk(String output) {
  // Parse the validator stdout for a line like: OK <0|1>
  // Accept CRLF or LF; search last occurrence defensively.
  final lines = output.split(RegExp(r'\r?\n'));
  for (final l in lines) {
    final m = RegExp(r'^OK\s+(\d+)\s*$').firstMatch(l.trim());
    if (m != null) {
      return m.group(1) == '1';
    }
  }
  return false;
}
