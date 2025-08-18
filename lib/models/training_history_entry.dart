class TrainingHistoryEntry {
  final String packId;
  final DateTime timestamp;
  final List<String> tags;
  final String? audience;
  final int? rating;
  final double? evScore;

  TrainingHistoryEntry({
    required this.packId,
    required this.timestamp,
    required this.tags,
    this.audience,
    this.rating,
    this.evScore,
  });

  factory TrainingHistoryEntry.fromJson(Map<String, dynamic> j) =>
      TrainingHistoryEntry(
        packId: j['packId'] as String? ?? '',
        timestamp:
            DateTime.tryParse(j['timestamp'] as String? ?? '') ??
            DateTime.now(),
        tags: [for (final t in (j['tags'] as List? ?? [])) t.toString()],
        audience: j['audience'] as String?,
        rating: (j['rating'] as num?)?.toInt(),
        evScore: (j['evScore'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
    'packId': packId,
    'timestamp': timestamp.toIso8601String(),
    if (tags.isNotEmpty) 'tags': tags,
    if (audience != null) 'audience': audience,
    if (rating != null) 'rating': rating,
    if (evScore != null) 'evScore': evScore,
  };
}
