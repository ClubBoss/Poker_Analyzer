class TheoryRecapPromptEvent {
  final String lessonId;
  final String trigger;
  final DateTime timestamp;
  final String outcome;

  const TheoryRecapPromptEvent({
    required this.lessonId,
    required this.trigger,
    required this.timestamp,
    required this.outcome,
  });

  Map<String, dynamic> toJson() => {
        'lessonId': lessonId,
        'trigger': trigger,
        'timestamp': timestamp.toIso8601String(),
        'outcome': outcome,
      };

  factory TheoryRecapPromptEvent.fromJson(Map<String, dynamic> json) =>
      TheoryRecapPromptEvent(
        lessonId: json['lessonId'] as String? ?? '',
        trigger: json['trigger'] as String? ?? '',
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
        outcome: json['outcome'] as String? ?? '',
      );
}
