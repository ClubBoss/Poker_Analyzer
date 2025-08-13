import 'dart:io';

class _SubtypeStats {
  int packs = 0;
  int spots = 0;
  void add(int spotCount) {
    packs += 1;
    spots += spotCount;
  }
}

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

Set<String> _parseSnippetKeys(String content) {
  final keys = <String>{};
  for (final line in content.split('\n')) {
    final match = RegExp(r'^(\S+):').firstMatch(line);
    if (match != null) keys.add(match.group(1)!);
  }
  return keys;
}

Map<String, Object> _parsePack(String content) {
  final subtypeMatch = RegExp(
    r'^subtype:\s*(\S+)',
    multiLine: true,
  ).firstMatch(content);
  final subtype = subtypeMatch?.group(1) ?? 'unknown';

  final tags = <String>[];
  final tagSection = RegExp(
    r'^tags:\n((?:\s+-\s*\S+\n)+)',
    multiLine: true,
  ).firstMatch(content);
  if (tagSection != null) {
    final lines = tagSection.group(1)!.trim().split('\n');
    for (final line in lines) {
      final m = RegExp(r'-\s*(\S+)').firstMatch(line);
      if (m != null) tags.add(m.group(1)!);
    }
  }

  final spots = RegExp(
    r'^\s{4}id:',
    multiLine: true,
  ).allMatches(content).length;

  return {'subtype': subtype, 'tags': tags, 'spots': spots};
}

void main(List<String> args) async {
  final argMap = _parseArgs(args);
  final packsDir = Directory(argMap['packs'] ?? 'assets/packs/l2');
  final snippetsFile = File(
    argMap['snippets'] ?? 'assets/theory/l2/snippets.yaml',
  );
  final outFile = File(argMap['out'] ?? 'build/reports/l2_report.md');

  final subtypeStats = <String, _SubtypeStats>{};
  final tagUniverse = <String>{};
  final bucketCounts = <String, int>{};
  final positionCounts = <String, int>{};

  final snippetKeys = _parseSnippetKeys(await snippetsFile.readAsString());
  final bucketTags = snippetKeys.where((k) => k.contains('bb')).toSet();
  final positionTags = {'ep', 'mp', 'co', 'btn', 'sb', 'bb'};

  final packFiles = packsDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.yaml'));

  for (final file in packFiles) {
    final parsed = _parsePack(await file.readAsString());
    final subtype = parsed['subtype'] as String;
    final spots = parsed['spots'] as int;
    final tags = parsed['tags'] as List<String>;
    subtypeStats.putIfAbsent(subtype, () => _SubtypeStats()).add(spots);
    tagUniverse.addAll(tags);
    for (final tag in tags) {
      if (bucketTags.contains(tag)) {
        bucketCounts[tag] = (bucketCounts[tag] ?? 0) + spots;
      }
      if (positionTags.contains(tag)) {
        positionCounts[tag] = (positionCounts[tag] ?? 0) + spots;
      }
    }
  }

  final covered = snippetKeys.intersection(tagUniverse);
  final coveragePct = snippetKeys.isEmpty
      ? 0
      : (covered.length / snippetKeys.length * 100);

  final report = StringBuffer();
  report.writeln('# L2 Metrics');
  report.writeln();
  report.writeln('## Packs');
  subtypeStats.forEach((subtype, stats) {
    report.writeln('- $subtype: ${stats.packs} packs, ${stats.spots} spots');
  });
  report.writeln();
  report.writeln('## Tag Coverage');
  report.writeln('- tag universe: ${tagUniverse.length}');
  report.writeln(
    '- snippet coverage: ${coveragePct.toStringAsFixed(1)}% (${covered.length}/${snippetKeys.length})',
  );
  report.writeln();
  report.writeln('## Stack Buckets');
  report.write(_renderHistogram(bucketCounts));
  report.writeln('## Positions');
  report.write(_renderHistogram(positionCounts));

  if (!outFile.parent.existsSync()) {
    outFile.parent.createSync(recursive: true);
  }
  await outFile.writeAsString(report.toString());

  // stdout summary
  print(
    'l2 metrics: tag-universe ${tagUniverse.length}, '
    'coverage ${coveragePct.toStringAsFixed(1)}%',
  );
  print(report.toString());
}
