class RecapCompletionLog {
  final String lessonId;
  final String tag;
  final DateTime timestamp;
  final Duration duration;

  const RecapCompletionLog({
    required this.lessonId,
    required this.tag,
    required this.timestamp,
    required this.duration,
  });

  Map<String, dynamic> toJson() => {
    'lessonId': lessonId,
    'tag': tag,
    'timestamp': timestamp.toIso8601String(),
    'durationMs': duration.inMilliseconds,
  };

  factory RecapCompletionLog.fromJson(Map<String, dynamic> json) =>
      RecapCompletionLog(
        lessonId: json['lessonId'] as String? ?? '',
        tag: json['tag'] as String? ?? '',
        timestamp:
            DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
        duration: Duration(milliseconds: (json['durationMs'] as int?) ?? 0),
      );
}
