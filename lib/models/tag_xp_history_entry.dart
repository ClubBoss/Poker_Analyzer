class TagXpHistoryEntry {
  final DateTime date;
  final int xp;
  final String source;

  TagXpHistoryEntry({
    required this.date,
    required this.xp,
    required this.source,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'xp': xp,
        'source': source,
      };

  factory TagXpHistoryEntry.fromJson(Map<String, dynamic> json) =>
      TagXpHistoryEntry(
        date:
            DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        xp: (json['xp'] as num?)?.toInt() ?? 0,
        source: json['source'] as String? ?? '',
      );
}
