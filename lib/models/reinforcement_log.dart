class ReinforcementLog {
  final String id;
  final String type;
  final String source;
  final DateTime timestamp;

  ReinforcementLog({
    required this.id,
    required this.type,
    required this.source,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'source': source,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ReinforcementLog.fromJson(Map<String, dynamic> j) => ReinforcementLog(
    id: j['id'] as String? ?? '',
    type: j['type'] as String? ?? '',
    source: j['source'] as String? ?? '',
    timestamp:
        DateTime.tryParse(j['timestamp'] as String? ?? '') ?? DateTime.now(),
  );
}
