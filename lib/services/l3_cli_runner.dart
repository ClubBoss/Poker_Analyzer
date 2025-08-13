import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../utils/mix_keys.dart';
import 'autogen_stats.dart';

class TargetMixConfig {
  final Map<String, double> mix;
  final double tolerance;

  // Per-key tolerance + guard (for tests/back-compat).
  final Map<String, double> _byKeyTol;
  final int _minTotal;

  double get defaultTol => tolerance; // test expects this name
  Map<String, double> get byKeyTol => _byKeyTol;
  int get minTotal => _minTotal;

  const TargetMixConfig({
    required this.mix,
    required this.tolerance, // alias for defaultTol
    Map<String, double>? byKeyTol,
    int minTotal = 0,
  })  : _byKeyTol = byKeyTol ?? const {},
        _minTotal = minTotal;
}

/// Tries inline JSON first, then treats [weights] as a file path.
/// Returns canonicalized target mix + tolerances/minTotal, or null.
TargetMixConfig? extractTargetMix(String weights) {
  dynamic weightsJson;
  try {
    weightsJson = json.decode(weights);
  } catch (_) {
    try {
      weightsJson = json.decode(File(weights).readAsStringSync());
    } catch (_) {
      // ignore
    }
  }

  Map<String, double>? mix;
  double defaultTol = 0.10; // back-compat default
  Map<String, double> byKeyTol = {};
  int minTotal = 0;

  double? _numOrStringDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  int? _numOrStringInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  void _mergeTolMap(dynamic raw) {
    if (raw is Map) {
      raw.forEach((key, value) {
        final canon = canonicalMixKey(key.toString()) ?? key.toString();
        final d = _numOrStringDouble(value);
        if (canon.isNotEmpty && d != null) {
          byKeyTol[canon] = d;
        }
      });
    }
  }

  if (weightsJson is Map) {
    // Default tolerance OR per-key map under the same key `mixTolerance`.
    final rawMixTol = weightsJson['mixTolerance'];
    final tolNum = _numOrStringDouble(rawMixTol);
    if (tolNum != null) {
      defaultTol = tolNum;
    } else {
      // If it's not a number, treat it as a per-key map.
      _mergeTolMap(rawMixTol);
    }

    // Additional aliases for the per-key tolerance map.
    _mergeTolMap(weightsJson['mixToleranceByKey']);
    _mergeTolMap(weightsJson['mixToleranceMap']);
    _mergeTolMap(weightsJson['toleranceByKey']);
    _mergeTolMap(weightsJson['tolerancesByKey']);
    _mergeTolMap(weightsJson['toleranceMap']);
    _mergeTolMap(weightsJson['perKeyTolerance']);
    _mergeTolMap(weightsJson['byKeyTol']);
    _mergeTolMap(weightsJson['byKey']); // very liberal fallback

    // Min sample guard (aliases, incl. mixMinTotal from test).
    final rawMin = weightsJson['mixMinTotal'] ??
        weightsJson['minTotal'] ??
        weightsJson['minTotalSamples'];
    final mt = _numOrStringInt(rawMin);
    if (mt != null) minTotal = mt;

    // Target mix (canonicalized)
    final rawMix = weightsJson['targetMix'];
    if (rawMix is Map) {
      final m = <String, double>{};
      rawMix.forEach((key, value) {
        final canon = canonicalMixKey(key.toString()) ?? key.toString();
        final d = _numOrStringDouble(value);
        if (canon.isNotEmpty && d != null) {
          m[canon] = d;
        }
      });
      if (m.isNotEmpty) mix = m;
    }
  }

  return mix != null
      ? TargetMixConfig(
          mix: mix!,
          tolerance: defaultTol,
          byKeyTol: byKeyTol,
          minTotal: minTotal,
        )
      : null;
}

class L3CliResult {
  final int exitCode;
  final String stdout;
  final String stderr;
  final String outPath;
  final String logPath;
  final List<String> warnings;

  L3CliResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.outPath,
    required this.logPath,
    required this.warnings,
  });
}

class L3CliRunner {
  const L3CliRunner();

  Future<L3CliResult> run({String? weights, String? weightsPreset}) async {
    final runDir = await Directory.systemTemp.createTemp('l3cli_run_');
    final outDir = await Directory.systemTemp.createTemp('l3cli_out_');
    final outPath = p.join(outDir.path, 'out.json');
    final logPath = p.join(outDir.path, 'out.log');

    final args = <String>[
      'run',
      'tool/l3/pack_run_cli.dart',
      '--dir',
      runDir.path,
      '--out',
      outPath,
    ];

    if (weightsPreset != null) {
      args
        ..add('--weightsPreset')
        ..add(weightsPreset);
    } else if (weights != null) {
      args
        ..add('--weights')
        ..add(weights);
    }

    final res = await Process.run('dart', args);
    final stdoutStr = res.stdout.toString();
    final stderrStr = res.stderr.toString();

    File(logPath)
        .writeAsStringSync('stdout:\n$stdoutStr\n\nstderr:\n$stderrStr');

    await runDir.delete(recursive: true);

    final warnings = <String>[];
    AutogenStats? stats;

    if (res.exitCode == 0) {
      // Surface CLI warnings already printed by the tool.
      for (final line in const LineSplitter().convert(stderrStr)) {
        final lower = line.toLowerCase();
        if (lower.contains('warning') ||
            lower.contains('monotone') ||
            lower.contains('both --weights and --weightspreset')) {
          warnings.add(line);
        }
      }

      // Compute autogen stats
      try {
        final reportJson = File(outPath).readAsStringSync();
        stats = buildAutogenStats(reportJson);
      } catch (_) {
        // ignore
      }

      // Validate targetMix if provided (with per-key tol & minTotal guard)
      if (stats != null && weights != null) {
        final target = extractTargetMix(weights);
        if (target != null && stats.total > 0) {
          if (target.minTotal > 0 && stats.total < target.minTotal) {
            // Not enough samples — skip checks.
          } else {
            const keys = <String>[
              'monotone',
              'twoTone',
              'rainbow',
              'paired',
              'aceHigh',
              'lowConnected',
              'broadwayHeavy',
            ];
            for (final key in keys) {
              final expected = target.mix[key];
              if (expected != null) {
                final actual = (stats.textures[key] ?? 0) / stats.total;
                final tol = target.byKeyTol[key] ?? target.defaultTol;
                final diff = actual - expected;
                if (diff.abs() > tol) {
                  final diffPp = (diff * 100).round();
                  final actualPct = (actual * 100).round();
                  final targetPct = (expected * 100).round();
                  final sign = diffPp >= 0 ? '+' : '';
                  warnings.add(
                    "L3 autogen: '$key' off by ${sign}${diffPp}pp (target ${targetPct}%, got ${actualPct}%).",
                  );
                }
              }
            }
          }
        }
      }
    }

    return L3CliResult(
      exitCode: res.exitCode,
      stdout: stdoutStr,
      stderr: stderrStr,
      outPath: outPath,
      logPath: logPath,
      warnings: warnings,
    );
  }

  static Future<void> revealInFolder(String filePath) async {
    final dir = p.dirname(filePath);
    if (Platform.isMacOS) {
      await Process.run('open', [dir]);
    } else if (Platform.isWindows) {
      await Process.run('explorer', [dir]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [dir]);
    }
  }
}
