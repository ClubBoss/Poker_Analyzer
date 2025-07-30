class TheoryPromptDismissEntry {
  final String lessonId;
  final String trigger;
  final DateTime timestamp;

  const TheoryPromptDismissEntry({
    required this.lessonId,
    required this.trigger,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'lessonId': lessonId,
        'trigger': trigger,
        'timestamp': timestamp.toIso8601String(),
      };

  factory TheoryPromptDismissEntry.fromJson(Map<String, dynamic> json) =>
      TheoryPromptDismissEntry(
        lessonId: json['lessonId'] as String? ?? '',
        trigger: json['trigger'] as String? ?? '',
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
      );
}
