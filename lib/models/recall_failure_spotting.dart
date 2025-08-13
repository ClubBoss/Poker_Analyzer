class RecallFailureSpotting {
  final String spotId;
  final DateTime timestamp;
  final String decayStage;

  const RecallFailureSpotting({
    required this.spotId,
    required this.timestamp,
    required this.decayStage,
  });

  Map<String, dynamic> toJson() => {
        'spotId': spotId,
        'timestamp': timestamp.toIso8601String(),
        'decayStage': decayStage,
      };

  factory RecallFailureSpotting.fromJson(Map<String, dynamic> json) =>
      RecallFailureSpotting(
        spotId: json['spotId'] as String? ?? '',
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        decayStage: json['decayStage'] as String? ?? '',
      );
}
