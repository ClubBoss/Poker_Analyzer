class BoosterValidationReport {
  final List<String> errors;
  final List<String> warnings;
  final bool isValid;

  const BoosterValidationReport({
    this.errors = const [],
    this.warnings = const [],
    this.isValid = true,
  });

  Map<String, dynamic> toJson() => {
    'errors': errors,
    'warnings': warnings,
    'isValid': isValid,
  };

  factory BoosterValidationReport.fromJson(Map<String, dynamic> j) =>
      BoosterValidationReport(
        errors: [for (final e in j['errors'] as List? ?? []) e.toString()],
        warnings: [for (final w in j['warnings'] as List? ?? []) w.toString()],
        isValid: j['isValid'] == true,
      );
}
