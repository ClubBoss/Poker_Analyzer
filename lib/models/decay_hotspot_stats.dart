class DecayHotspotStat {
  final String id;
  final int count;
  final double? successRate;
  final DateTime lastSeen;
  final Map<String, int> decayStageDistribution;

  const DecayHotspotStat({
    required this.id,
    required this.count,
    this.successRate,
    required this.lastSeen,
    required this.decayStageDistribution,
  });
}

class DecayHotspotStats {
  final List<DecayHotspotStat> topTags;
  final List<DecayHotspotStat> topSpotIds;

  const DecayHotspotStats({required this.topTags, required this.topSpotIds});
}
