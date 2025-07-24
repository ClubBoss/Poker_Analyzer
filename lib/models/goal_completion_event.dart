class GoalCompletionEvent {
  final String tag;
  final DateTime timestamp;

  const GoalCompletionEvent({required this.tag, required this.timestamp});

  Map<String, dynamic> toJson() => {
        'tag': tag,
        'timestamp': timestamp.toIso8601String(),
      };

  factory GoalCompletionEvent.fromJson(Map<String, dynamic> json) =>
      GoalCompletionEvent(
        tag: json['tag'] as String? ?? '',
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
      );
}
