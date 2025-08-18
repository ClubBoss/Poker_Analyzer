enum LearningEventType { trackCompleted, streak, masteryUp }

class LearningEvent {
  final DateTime date;
  final LearningEventType type;
  final String label;
  final Map<String, dynamic>? meta;

  LearningEvent({
    required this.date,
    required this.type,
    required this.label,
    this.meta,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'type': type.name,
    'label': label,
    if (meta != null) 'meta': meta,
  };

  factory LearningEvent.fromJson(Map<String, dynamic> json) => LearningEvent(
    date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
    type: LearningEventType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => LearningEventType.trackCompleted,
    ),
    label: json['label'] as String? ?? '',
    meta: json['meta'] is Map
        ? Map<String, dynamic>.from(json['meta'] as Map)
        : null,
  );
}
