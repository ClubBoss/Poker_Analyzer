class RemedialSpec {
  final List<String> topTags;
  final Map<String, int> textureCounts;
  final int streetBias;
  final double minAccuracyTarget;

  const RemedialSpec({
    this.topTags = const [],
    this.textureCounts = const {},
    this.streetBias = 0,
    this.minAccuracyTarget = 0,
  });
}
