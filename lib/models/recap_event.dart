class RecapEvent {
  final String lessonId;
  final String trigger;
  final String eventType;
  final DateTime timestamp;

  const RecapEvent({
    required this.lessonId,
    required this.trigger,
    required this.eventType,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'lessonId': lessonId,
    'trigger': trigger,
    'eventType': eventType,
    'timestamp': timestamp.toIso8601String(),
  };

  factory RecapEvent.fromJson(Map<String, dynamic> json) => RecapEvent(
    lessonId: json['lessonId'] as String? ?? '',
    trigger: json['trigger'] as String? ?? '',
    eventType: json['eventType'] as String? ?? '',
    timestamp:
        DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
  );
}
