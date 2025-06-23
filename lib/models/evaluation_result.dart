class EvaluationResult {
  final bool correct;
  final String expectedAction;
  final String? hint;

  /// Equity of the hand given the user's chosen action.
  final double userEquity;

  /// Equity of the hand if the optimal action was taken.
  final double expectedEquity;

  EvaluationResult({
    required this.correct,
    required this.expectedAction,
    required this.userEquity,
    required this.expectedEquity,
    this.hint,
  });

  Map<String, dynamic> toJson() => {
        'correct': correct,
        'expectedAction': expectedAction,
        'userEquity': userEquity,
        'expectedEquity': expectedEquity,
        if (hint != null) 'hint': hint,
      };

  factory EvaluationResult.fromJson(Map<String, dynamic> json) => EvaluationResult(
        correct: json['correct'] as bool? ?? false,
        expectedAction: json['expectedAction'] as String? ?? '',
        userEquity: (json['userEquity'] as num?)?.toDouble() ?? 0.0,
        expectedEquity: (json['expectedEquity'] as num?)?.toDouble() ?? 0.0,
        hint: json['hint'] as String?,
      );
}
