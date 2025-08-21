class RecallBoostViewEntry {
  final String tag;
  final String nodeId;
  final DateTime timestamp;
  final int durationMs;

  const RecallBoostViewEntry({
    required this.tag,
    required this.nodeId,
    required this.timestamp,
    required this.durationMs,
  });

  Map<String, dynamic> toJson() => {
    'tag': tag,
    'nodeId': nodeId,
    'timestamp': timestamp.toIso8601String(),
    'durationMs': durationMs,
  };

  factory RecallBoostViewEntry.fromJson(Map<String, dynamic> json) =>
      RecallBoostViewEntry(
        tag: json['tag'] as String? ?? '',
        nodeId: json['nodeId'] as String? ?? '',
        timestamp:
            DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
        durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
      );
}
