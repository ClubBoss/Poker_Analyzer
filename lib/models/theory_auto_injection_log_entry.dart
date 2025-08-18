class TheoryAutoInjectionLogEntry {
  final String spotId;
  final String lessonId;
  final DateTime timestamp;

  const TheoryAutoInjectionLogEntry({
    required this.spotId,
    required this.lessonId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'spotId': spotId,
    'lessonId': lessonId,
    'timestamp': timestamp.toIso8601String(),
  };

  factory TheoryAutoInjectionLogEntry.fromJson(Map<String, dynamic> json) =>
      TheoryAutoInjectionLogEntry(
        spotId: json['spotId']?.toString() ?? '',
        lessonId: json['lessonId']?.toString() ?? '',
        timestamp:
            DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
            DateTime.now(),
      );
}
