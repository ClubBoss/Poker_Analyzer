class TrainingHealthReport {
  final List<(String, String)> issues;
  final int errors;
  final int warnings;
  const TrainingHealthReport({
    required this.issues,
    required this.errors,
    required this.warnings,
  });
  Map<String, dynamic> toJson() => {
    'issues': [
      for (final e in issues) [e.$1, e.$2],
    ],
    'errors': errors,
    'warnings': warnings,
  };
  factory TrainingHealthReport.fromJson(Map<String, dynamic> json) {
    final list = <(String, String)>[];
    for (final e in json['issues'] as List? ?? []) {
      if (e is List && e.length >= 2) {
        list.add((e[0].toString(), e[1].toString()));
      }
    }
    return TrainingHealthReport(
      issues: list,
      errors: (json['errors'] as num?)?.toInt() ?? 0,
      warnings: (json['warnings'] as num?)?.toInt() ?? 0,
    );
  }
}
