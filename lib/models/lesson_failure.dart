class LessonFailure {
  final DateTime timestamp;
  final double evLoss;

  const LessonFailure({required this.timestamp, required this.evLoss});

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'evLoss': evLoss,
  };

  factory LessonFailure.fromJson(Map<String, dynamic> j) => LessonFailure(
    timestamp:
        DateTime.tryParse(j['timestamp']?.toString() ?? '') ?? DateTime.now(),
    evLoss: (j['evLoss'] as num?)?.toDouble() ?? 0,
  );
}
