class PackRatingReport {
  final int score;
  final List<String> warnings;
  final List<String> insights;
  const PackRatingReport({
    this.score = 0,
    this.warnings = const [],
    this.insights = const [],
  });
  Map<String, dynamic> toJson() => {
        'score': score,
        'warnings': warnings,
        'insights': insights,
      };
  factory PackRatingReport.fromJson(Map<String, dynamic> j) => PackRatingReport(
        score: (j['score'] as num?)?.toInt() ?? 0,
        warnings: [for (final w in j['warnings'] as List? ?? []) w.toString()],
        insights: [for (final i in j['insights'] as List? ?? []) i.toString()],
      );
}
