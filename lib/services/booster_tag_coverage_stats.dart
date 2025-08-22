import 'theory_yaml_importer.dart';

class BoosterTagCoverageStats {
  BoosterTagCoverageStats();

  Future<Map<String, int>> loadCoverage({
    String dir = 'yaml_out/boosters',
  }) async {
    const importer = TheoryYamlImporter();
    final packs = await importer.importFromDirectory(dir);
    final Map<String, int> counts = {};
    for (final p in packs) {
      if (p.meta['booster'] != true) continue;
      for (final t in p.tags) {
        final tag = t.trim();
        if (tag.isEmpty) continue;
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    return counts;
  }

  Future<String> buildReport({String dir = 'yaml_out/boosters'}) async {
    final counts = await loadCoverage(dir: dir);
    if (counts.isEmpty) return 'No booster packs found';
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(10).toList();
    final bottom = entries.reversed.take(10).toList();
    final buffer = StringBuffer('Top 10 tags:\n');
    for (final e in top) {
      buffer.writeln('${e.key}: ${e.value}');
    }
    buffer.writeln('\nBottom 10 tags:');
    for (final e in bottom) {
      buffer.writeln('${e.key}: ${e.value}');
    }
    return buffer.toString();
  }
}
