class TrainingAttempt {
  final String packId;
  final String spotId;
  final DateTime timestamp;
  final double accuracy;
  final double ev;
  final double icm;

  TrainingAttempt({
    required this.packId,
    required this.spotId,
    required this.timestamp,
    required this.accuracy,
    required this.ev,
    required this.icm,
  });

  factory TrainingAttempt.fromJson(Map<String, dynamic> j) => TrainingAttempt(
        packId: j['packId'] as String? ?? '',
        spotId: j['spotId'] as String? ?? '',
        timestamp:
            DateTime.tryParse(j['timestamp'] as String? ?? '') ?? DateTime.now(),
        accuracy: (j['accuracy'] as num?)?.toDouble() ?? 0,
        ev: (j['ev'] as num?)?.toDouble() ?? 0,
        icm: (j['icm'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'packId': packId,
        'spotId': spotId,
        'timestamp': timestamp.toIso8601String(),
        'accuracy': accuracy,
        'ev': ev,
        'icm': icm,
      };
}
