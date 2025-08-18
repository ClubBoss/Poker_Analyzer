class BoosterAnomalyReport {
  final List<String> duplicatedHands;
  final List<String> repeatedBoards;
  final List<String> evOutliers;
  final List<String> weakExplanations;

  const BoosterAnomalyReport({
    this.duplicatedHands = const [],
    this.repeatedBoards = const [],
    this.evOutliers = const [],
    this.weakExplanations = const [],
  });

  Map<String, dynamic> toJson() => {
    'duplicatedHands': duplicatedHands,
    'repeatedBoards': repeatedBoards,
    'evOutliers': evOutliers,
    'weakExplanations': weakExplanations,
  };

  factory BoosterAnomalyReport.fromJson(Map<String, dynamic> j) =>
      BoosterAnomalyReport(
        duplicatedHands: [
          for (final v in j['duplicatedHands'] as List? ?? []) v.toString(),
        ],
        repeatedBoards: [
          for (final v in j['repeatedBoards'] as List? ?? []) v.toString(),
        ],
        evOutliers: [
          for (final v in j['evOutliers'] as List? ?? []) v.toString(),
        ],
        weakExplanations: [
          for (final v in j['weakExplanations'] as List? ?? []) v.toString(),
        ],
      );
}
