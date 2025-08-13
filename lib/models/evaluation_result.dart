class EvaluationResult {
  final bool correct;
  final String expectedAction;
  final String? hint;

  /// Equity of the hand given the user's chosen action.
  final double userEquity;

  /// Equity of the hand if the optimal action was taken.
  final double expectedEquity;

  final double? ev;

  final double? icmEv;
  final List<Map<String, dynamic>>? streets;

  EvaluationResult({
    required this.correct,
    required this.expectedAction,
    required this.userEquity,
    required this.expectedEquity,
    this.ev,
    this.icmEv,
    this.hint,
    this.streets,
  });

  Map<String, dynamic> toJson() => {
        'correct': correct,
        'expectedAction': expectedAction,
        'userEquity': userEquity,
        'expectedEquity': expectedEquity,
        if (ev != null) 'ev': ev,
        if (icmEv != null) 'icmEv': icmEv,
        if (hint != null) 'hint': hint,
        if (streets != null && streets!.isNotEmpty) 'streets': streets,
      };

  factory EvaluationResult.fromJson(Map<String, dynamic> json) =>
      EvaluationResult(
        correct: json['correct'] as bool? ?? false,
        expectedAction: json['expectedAction'] as String? ?? '',
        userEquity: (json['userEquity'] as num?)?.toDouble() ?? 0.0,
        expectedEquity: (json['expectedEquity'] as num?)?.toDouble() ?? 0.0,
        ev: (json['ev'] as num?)?.toDouble(),
        icmEv: (json['icmEv'] as num?)?.toDouble(),
        hint: json['hint'] as String?,
        streets: (json['streets'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      );
}
