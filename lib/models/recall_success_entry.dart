class RecallSuccessEntry {
  final String tag;
  final DateTime timestamp;
  final String? source;

  const RecallSuccessEntry({
    required this.tag,
    required this.timestamp,
    this.source,
  });

  Map<String, dynamic> toJson() => {
        'tag': tag,
        'timestamp': timestamp.toIso8601String(),
        if (source != null && source!.isNotEmpty) 'source': source,
      };

  factory RecallSuccessEntry.fromJson(Map<String, dynamic> json) =>
      RecallSuccessEntry(
        tag: json['tag'] as String? ?? '',
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
        source: json['source'] as String?,
      );
}
