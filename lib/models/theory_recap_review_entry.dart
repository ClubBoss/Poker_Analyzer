class TheoryRecapReviewEntry {
  final String lessonId;
  final String trigger;
  final DateTime timestamp;

  const TheoryRecapReviewEntry({
    required this.lessonId,
    required this.trigger,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'lessonId': lessonId,
    'trigger': trigger,
    'timestamp': timestamp.toIso8601String(),
  };

  factory TheoryRecapReviewEntry.fromJson(Map<String, dynamic> json) =>
      TheoryRecapReviewEntry(
        lessonId: json['lessonId'] as String? ?? '',
        trigger: json['trigger'] as String? ?? '',
        timestamp:
            DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
      );
}
