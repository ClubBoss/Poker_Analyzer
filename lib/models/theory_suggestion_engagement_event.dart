class TheorySuggestionEngagementEvent {
  final String lessonId;
  final String action; // 'suggested' | 'expanded' | 'opened'
  final DateTime timestamp;

  const TheorySuggestionEngagementEvent({
    required this.lessonId,
    required this.action,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'lessonId': lessonId,
        'action': action,
        'timestamp': timestamp.toIso8601String(),
      };

  factory TheorySuggestionEngagementEvent.fromJson(Map<String, dynamic> json) {
    return TheorySuggestionEngagementEvent(
      lessonId: json['lessonId'] as String? ?? '',
      action: json['action'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
