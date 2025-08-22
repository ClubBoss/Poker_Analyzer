enum DecayLevel { ok, warning, critical }

class DecayHeatmapEntry {
  final String tag;
  final double decay;
  final DecayLevel level;

  DecayHeatmapEntry({
    required this.tag,
    required this.decay,
    required this.level,
  });
}

class DecayHeatmapModelGenerator {
  List<DecayHeatmapEntry> generate(Map<String, double> tagDecayScores) {
    final result = <DecayHeatmapEntry>[];
    for (final entry in tagDecayScores.entries) {
      final score = entry.value;
      final level = score > 60
          ? DecayLevel.critical
          : score > 30
          ? DecayLevel.warning
          : DecayLevel.ok;
      result.add(DecayHeatmapEntry(tag: entry.key, decay: score, level: level));
    }
    return result;
  }
}
