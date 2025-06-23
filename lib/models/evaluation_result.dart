class EvaluationResult {
  final bool correct;
  final String expectedAction;
  final String? hint;

  EvaluationResult({
    required this.correct,
    required this.expectedAction,
    this.hint,
  });

  Map<String, dynamic> toJson() => {
        'correct': correct,
        'expectedAction': expectedAction,
        if (hint != null) 'hint': hint,
      };

  factory EvaluationResult.fromJson(Map<String, dynamic> json) => EvaluationResult(
        correct: json['correct'] as bool? ?? false,
        expectedAction: json['expectedAction'] as String? ?? '',
        hint: json['hint'] as String?,
      );
}
