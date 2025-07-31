class DecayTagReinforcementEvent {
  final String tag;
  final double delta;
  final DateTime timestamp;

  DecayTagReinforcementEvent({
    required this.tag,
    required this.delta,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'tag': tag,
        'delta': delta,
        'timestamp': timestamp.toIso8601String(),
      };

  factory DecayTagReinforcementEvent.fromJson(Map<String, dynamic> json) =>
      DecayTagReinforcementEvent(
        tag: json['tag'] as String? ?? '',
        delta: (json['delta'] as num?)?.toDouble() ?? 0.0,
        timestamp:
            DateTime.tryParse(json['timestamp'] as String? ?? '') ??
                DateTime.now(),
      );
}
