class RecallHotspotEntry {
  final String id;
  final int count;

  const RecallHotspotEntry({required this.id, required this.count});
}

class RecallHotspotReport {
  final List<RecallHotspotEntry> topTags;
  final List<RecallHotspotEntry> topSpotIds;

  const RecallHotspotReport({required this.topTags, required this.topSpotIds});
}
