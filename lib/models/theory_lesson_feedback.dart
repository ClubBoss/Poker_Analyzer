enum TheoryLessonFeedbackChoice { useful, unclear, hard }

class TheoryLessonFeedback {
  final String lessonId;
  final TheoryLessonFeedbackChoice choice;
  final DateTime timestamp;

  TheoryLessonFeedback({
    required this.lessonId,
    required this.choice,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory TheoryLessonFeedback.fromJson(Map<String, dynamic> json) {
    return TheoryLessonFeedback(
      lessonId: json['lessonId'] as String? ?? '',
      choice: TheoryLessonFeedbackChoice.values[json['choice'] as int? ?? 0],
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'lessonId': lessonId,
    'choice': choice.index,
    'timestamp': timestamp.toIso8601String(),
  };
}
