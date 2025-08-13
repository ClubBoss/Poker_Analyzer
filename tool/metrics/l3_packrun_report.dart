import 'dart:convert';
import 'dart:io';

Map<String, String> _parseArgs(List<String> args) {
  final map = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg.startsWith('--') && i + 1 < args.length) {
      map[arg.substring(2)] = args[++i];
    }
  }
  return map;
}

String _renderHistogram(Map<String, int> counts) {
  if (counts.isEmpty) return '';
  final maxCount = counts.values.fold<int>(0, (a, b) => a > b ? a : b);
  final buffer = StringBuffer();
  final keys = counts.keys.toList()..sort();
  for (final key in keys) {
    final count = counts[key]!;
    final barLen = maxCount == 0 ? 0 : ((count / maxCount) * 20).round();
    final bar = ''.padRight(barLen, '#');
    buffer.writeln('- $key: $count $bar');
  }
  return buffer.toString();
}

void main(List<String> args) async {
  try {
    final argMap = _parseArgs(args);
    final reportsArg = argMap['reports'];
    if (reportsArg == null || reportsArg.isEmpty) {
      print('l3 metrics: no reports provided');
      return;
    }
    final outFile = File(argMap['out'] ?? 'build/reports/l3_report.md');
    final reportPaths =
        reportsArg.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);

    var totalSpots = 0;
    var jamCount = 0.0;
    final textureCounts = <String, int>{};
    final presetCounts = <String, int>{};
    final sprHistogram = <String, int>{};

    for (final path in reportPaths) {
      final file = File(path);
      if (!file.existsSync()) continue;
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final summary = (json['summary'] as Map<String, dynamic>?) ?? {};
      final total = (summary['total'] as num?)?.toInt() ?? 0;
      final avgJam = (summary['avgJamRate'] as num?)?.toDouble() ?? 0;
      final textures =
          (summary['textureCounts'] as Map<String, dynamic>?) ?? {};
      final presets = (summary['presetCounts'] as Map<String, dynamic>?) ?? {};
      final sprHist = (summary['sprHistogram'] as Map<String, dynamic>?) ?? {};

      totalSpots += total;
      jamCount += avgJam * total;
      textures.forEach((k, v) {
        textureCounts[k] = (textureCounts[k] ?? 0) + (v as num).toInt();
      });
      presets.forEach((k, v) {
        presetCounts[k] = (presetCounts[k] ?? 0) + (v as num).toInt();
      });
      sprHist.forEach((k, v) {
        sprHistogram[k] = (sprHistogram[k] ?? 0) + (v as num).toInt();
      });
    }

    final jamRate = totalSpots == 0 ? 0 : jamCount / totalSpots;

    final buffer = StringBuffer();
    buffer.writeln('# L3 PackRun Metrics');
    buffer.writeln();
    buffer.writeln('- total spots: $totalSpots');
    buffer.writeln('- jam rate: ${(jamRate * 100).toStringAsFixed(1)}%');
    buffer.writeln();
    buffer.writeln('## Texture Distribution');
    buffer.write(_renderHistogram(textureCounts));
    if (presetCounts.isNotEmpty) {
      buffer.writeln('## Presets');
      buffer.write(_renderHistogram(presetCounts));
    }
    if (sprHistogram.isNotEmpty) {
      buffer.writeln('## SPR Distribution');
      buffer.write(_renderHistogram(sprHistogram));
    }

    if (!outFile.parent.existsSync()) {
      outFile.parent.createSync(recursive: true);
    }
    await outFile.writeAsString(buffer.toString());

    print(
      'l3 metrics: total $totalSpots, jam rate ${(jamRate * 100).toStringAsFixed(1)}%',
    );
    print(buffer.toString());
  } catch (e) {
    stderr.writeln('l3 metrics error: $e');
  }
}
