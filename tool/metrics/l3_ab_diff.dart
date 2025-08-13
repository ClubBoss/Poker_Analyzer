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

void _renderSection(StringBuffer buf, String title, Map<String, dynamic> base,
    Map<String, dynamic> challenger) {
  buf.writeln('\n### $title');
  buf.writeln('| key | base | challenger | Δ |');
  buf.writeln('| --- | --- | --- | --- |');
  final keys = {
    ...base.keys.cast<String>(),
    ...challenger.keys.cast<String>(),
  }.toList()
    ..sort();
  for (final k in keys) {
    final b = (base[k] as num? ?? 0).toInt();
    final c = (challenger[k] as num? ?? 0).toInt();
    final d = c - b;
    final delta = d >= 0 ? '+$d' : '$d';
    buf.writeln('| $k | $b | $c | $delta |');
  }
}

void main(List<String> args) async {
  final argMap = _parseArgs(args);
  final basePath = argMap['base'];
  final challPath = argMap['challenger'];
  final outPath = argMap['out'];
  final buffer = StringBuffer();
  try {
    final baseJson = jsonDecode(await File(basePath ?? '').readAsString())
        as Map<String, dynamic>;
    final challJson = jsonDecode(await File(challPath ?? '').readAsString())
        as Map<String, dynamic>;
    final baseSummary =
        (baseJson['summary'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final challSummary =
        (challJson['summary'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    final baseJam = (baseSummary['avgJamRate'] as num? ?? 0).toDouble();
    final challJam = (challSummary['avgJamRate'] as num? ?? 0).toDouble();
    buffer.writeln('| metric | base | challenger | Δ |');
    buffer.writeln('| --- | --- | --- | --- |');
    buffer.writeln(
        '| jamRate | ${baseJam.toStringAsFixed(3)} | ${challJam.toStringAsFixed(3)} | ${(challJam - baseJam).toStringAsFixed(3)} |');

    _renderSection(
        buffer,
        'Textures',
        (baseSummary['textureCounts'] as Map<String, dynamic>?) ?? {},
        (challSummary['textureCounts'] as Map<String, dynamic>?) ?? {});
    _renderSection(
        buffer,
        'Presets',
        (baseSummary['presetCounts'] as Map<String, dynamic>?) ?? {},
        (challSummary['presetCounts'] as Map<String, dynamic>?) ?? {});
    _renderSection(
        buffer,
        'SPR',
        (baseSummary['sprHistogram'] as Map<String, dynamic>?) ?? {},
        (challSummary['sprHistogram'] as Map<String, dynamic>?) ?? {});

    if (outPath != null) {
      final outFile = File(outPath);
      outFile.parent.createSync(recursive: true);
      await outFile.writeAsString(buffer.toString());
    } else {
      print(buffer.toString());
    }
  } catch (e) {
    stderr.writeln('l3_ab_diff error: $e');
  }
}
