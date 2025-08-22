class TheoryMiniLessonUsageEvent {
  final String lessonId;
  final String source;
  final DateTime timestamp;

  const TheoryMiniLessonUsageEvent({
    required this.lessonId,
    required this.source,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'lessonId': lessonId,
    'source': source,
    'timestamp': timestamp.toIso8601String(),
  };

  factory TheoryMiniLessonUsageEvent.fromJson(Map<String, dynamic> json) =>
      TheoryMiniLessonUsageEvent(
        lessonId: json['lessonId'] as String? ?? '',
        source: json['source'] as String? ?? '',
        timestamp:
            DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
      );
}
