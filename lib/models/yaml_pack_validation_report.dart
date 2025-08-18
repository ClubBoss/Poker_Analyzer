class YamlPackValidationReport {
  final List<String> errors;
  final List<String> warnings;
  final bool isValid;
  const YamlPackValidationReport({
    this.errors = const [],
    this.warnings = const [],
    this.isValid = true,
  });
  Map<String, dynamic> toJson() => {
    'errors': errors,
    'warnings': warnings,
    'isValid': isValid,
  };
  factory YamlPackValidationReport.fromJson(Map<String, dynamic> j) =>
      YamlPackValidationReport(
        errors: [for (final e in j['errors'] as List? ?? []) e.toString()],
        warnings: [for (final w in j['warnings'] as List? ?? []) w.toString()],
        isValid: j['isValid'] == true,
      );
}
