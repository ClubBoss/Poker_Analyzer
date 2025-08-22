class SummaryResult {
  final int totalHands;
  final int correct;
  final int incorrect;
  final double accuracy;
  final Map<String, int> mistakeTagFrequencies;
  final Map<String, int> streetBreakdown;
  final Map<String, int> positionMistakeFrequencies;
  final Map<int, double> accuracyPerSession;

  SummaryResult({
    required this.totalHands,
    required this.correct,
    required this.incorrect,
    required this.accuracy,
    Map<String, int>? mistakeTagFrequencies,
    Map<String, int>? streetBreakdown,
    Map<String, int>? positionMistakeFrequencies,
    Map<int, double>? accuracyPerSession,
  }) : mistakeTagFrequencies = mistakeTagFrequencies ?? const {},
       streetBreakdown = streetBreakdown ?? const {},
       positionMistakeFrequencies = positionMistakeFrequencies ?? const {},
       accuracyPerSession = accuracyPerSession ?? const {};

  Map<String, dynamic> toJson() => {
    'totalHands': totalHands,
    'correct': correct,
    'incorrect': incorrect,
    'accuracy': accuracy,
    if (mistakeTagFrequencies.isNotEmpty)
      'mistakeTagFrequencies': mistakeTagFrequencies,
    if (streetBreakdown.isNotEmpty) 'streetBreakdown': streetBreakdown,
    if (positionMistakeFrequencies.isNotEmpty)
      'positionMistakeFrequencies': positionMistakeFrequencies,
    if (accuracyPerSession.isNotEmpty)
      'accuracyPerSession': accuracyPerSession.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
  };

  factory SummaryResult.fromJson(Map<String, dynamic> json) {
    final tagFreq = <String, int>{};
    (json['mistakeTagFrequencies'] as Map? ?? {}).forEach((key, value) {
      tagFreq[key as String] = value as int;
    });
    final streets = <String, int>{};
    (json['streetBreakdown'] as Map? ?? {}).forEach((key, value) {
      streets[key as String] = value as int;
    });
    final positions = <String, int>{};
    (json['positionMistakeFrequencies'] as Map? ?? {}).forEach((key, value) {
      positions[key as String] = value as int;
    });
    final sessions = <int, double>{};
    (json['accuracyPerSession'] as Map? ?? {}).forEach((key, value) {
      sessions[int.parse(key as String)] = (value as num).toDouble();
    });
    return SummaryResult(
      totalHands: json['totalHands'] as int? ?? 0,
      correct: json['correct'] as int? ?? 0,
      incorrect: json['incorrect'] as int? ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      mistakeTagFrequencies: tagFreq,
      streetBreakdown: streets,
      positionMistakeFrequencies: positions,
      accuracyPerSession: sessions,
    );
  }
}
