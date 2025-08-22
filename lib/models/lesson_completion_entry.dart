class LessonCompletionEntry {
  final String lessonId;
  final DateTime timestamp;

  LessonCompletionEntry({required this.lessonId, required this.timestamp});

  Map<String, dynamic> toJson() => {
    'lessonId': lessonId,
    'timestamp': timestamp.toUtc().toIso8601String(),
  };

  factory LessonCompletionEntry.fromJson(Map<String, dynamic> json) =>
      LessonCompletionEntry(
        lessonId: json['lessonId'] as String? ?? '',
        timestamp:
            DateTime.tryParse(json['timestamp'] as String? ?? '')?.toUtc() ??
            DateTime.now().toUtc(),
      );
}
