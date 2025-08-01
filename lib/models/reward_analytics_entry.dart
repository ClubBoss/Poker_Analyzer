class RewardAnalyticsEntry {
  final String tag;
  final String rewardType;
  final DateTime timestamp;

  const RewardAnalyticsEntry({
    required this.tag,
    required this.rewardType,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'tag': tag,
        'rewardType': rewardType,
        'timestamp': timestamp.toIso8601String(),
      };

  factory RewardAnalyticsEntry.fromJson(Map<String, dynamic> json) {
    return RewardAnalyticsEntry(
      tag: json['tag'] as String? ?? '',
      rewardType: json['rewardType'] as String? ?? '',
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
