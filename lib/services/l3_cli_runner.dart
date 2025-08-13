import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../utils/mix_keys.dart';
import 'autogen_stats.dart';

({Map<String, double> mix, double tolerance})? extractTargetMix(
  String weights,
) {
  dynamic weightsJson;
  try {
    weightsJson = json.decode(weights);
  } catch (_) {
    try {
      weightsJson = json.decode(File(weights).readAsStringSync());
    } catch (_) {
      /* ignore */
    }
  }

  Map<String, double>? mix;
  double tolerance = 0.10;
  if (weightsJson is Map) {
    final rawTolerance = weightsJson['mixTolerance'];
    if (rawTolerance is num) {
      tolerance = rawTolerance.toDouble();
    }
    final rawMix = weightsJson['targetMix'];
    if (rawMix is Map) {
      mix = {};
      rawMix.forEach((key, value) {
        final canon = canonicalMixKey(key.toString());
        if (canon != null && value is num) {
          mix![canon] = value.toDouble();
        }
      });
    }
  }
  return mix != null ? (mix: mix, tolerance: tolerance) : null;
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

    final args = [
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

    File(
      logPath,
    ).writeAsStringSync('stdout:\n$stdoutStr\n\nstderr:\n$stderrStr');

    await runDir.delete(recursive: true);

    final warnings = <String>[];
    AutogenStats? stats;
    if (res.exitCode == 0) {
      for (final line in const LineSplitter().convert(stderrStr)) {
        final lower = line.toLowerCase();
        if (lower.contains('warning') ||
            lower.contains('monotone') ||
            lower.contains('both --weights and --weightspreset')) {
          warnings.add(line);
        }
      }

      try {
        final reportJson = File(outPath).readAsStringSync();
        stats = buildAutogenStats(reportJson);
      } catch (_) {}

      if (stats != null && weights != null) {
        final target = extractTargetMix(weights);
        if (target != null && stats.total > 0) {
          const keys = [
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
              final diff = actual - expected;
              if (diff.abs() > target.tolerance) {
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
