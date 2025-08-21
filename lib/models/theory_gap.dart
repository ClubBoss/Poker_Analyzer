class TheoryGap {
  final String topic;
  final int coverageCount;
  final int targetCoverage;
  final List<String> candidatePacks;
  final double priorityScore;

  const TheoryGap({
    required this.topic,
    required this.coverageCount,
    required this.targetCoverage,
    required this.candidatePacks,
    required this.priorityScore,
  });

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'coverageCount': coverageCount,
        'targetCoverage': targetCoverage,
        'candidatePacks': candidatePacks,
        'priorityScore': priorityScore,
      };

  factory TheoryGap.fromJson(Map<String, dynamic> json) => TheoryGap(
        topic: json['topic'] as String? ?? '',
        coverageCount: json['coverageCount'] as int? ?? 0,
        targetCoverage: json['targetCoverage'] as int? ?? 0,
        candidatePacks:
            (json['candidatePacks'] as List?)?.cast<String>() ?? const [],
        priorityScore: (json['priorityScore'] as num?)?.toDouble() ?? 0,
      );
}
