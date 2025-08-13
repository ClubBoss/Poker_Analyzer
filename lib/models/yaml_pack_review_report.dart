class YamlPackReviewReport {
  final List<String> warnings;
  final List<String> suggestions;
  const YamlPackReviewReport({
    this.warnings = const [],
    this.suggestions = const [],
  });
  Map<String, dynamic> toJson() => {
        'warnings': warnings,
        'suggestions': suggestions,
      };
  factory YamlPackReviewReport.fromJson(Map<String, dynamic> j) =>
      YamlPackReviewReport(
        warnings: [for (final w in j['warnings'] as List? ?? []) w.toString()],
        suggestions: [
          for (final s in j['suggestions'] as List? ?? []) s.toString()
        ],
      );
}
