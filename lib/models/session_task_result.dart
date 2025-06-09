class SessionTaskResult {
  final String question;
  final String selectedAnswer;
  final String correctAnswer;
  final bool correct;

  SessionTaskResult({
    required this.question,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.correct,
  });

  Map<String, dynamic> toJson() => {
        'question': question,
        'selectedAnswer': selectedAnswer,
        'correctAnswer': correctAnswer,
        'correct': correct,
      };

  factory SessionTaskResult.fromJson(Map<String, dynamic> json) => SessionTaskResult(
        question: json['question'] as String? ?? '',
        selectedAnswer: json['selectedAnswer'] as String? ?? '',
        correctAnswer: json['correctAnswer'] as String? ?? '',
        correct: json['correct'] as bool? ?? false,
      );
}
