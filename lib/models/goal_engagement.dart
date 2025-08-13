class GoalEngagement {
  final String tag;
  final String action; // "start", "skip", "dismiss", "completed"
  final DateTime timestamp;

  const GoalEngagement({
    required this.tag,
    required this.action,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'tag': tag,
        'action': action,
        'timestamp': timestamp.toIso8601String(),
      };

  factory GoalEngagement.fromJson(Map<String, dynamic> json) => GoalEngagement(
        tag: json['tag'] as String? ?? '',
        action: json['action'] as String? ?? '',
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
      );
}
