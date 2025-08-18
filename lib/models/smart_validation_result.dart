import 'yaml_pack_validation_report.dart';

class SmartValidationResult {
  final YamlPackValidationReport before;
  final YamlPackValidationReport after;
  final List<String> fixed;
  const SmartValidationResult({
    this.before = const YamlPackValidationReport(),
    this.after = const YamlPackValidationReport(),
    this.fixed = const [],
  });
  Map<String, dynamic> toJson() => {
    'before': before.toJson(),
    'after': after.toJson(),
    'fixed': fixed,
  };
  factory SmartValidationResult.fromJson(Map<String, dynamic> j) =>
      SmartValidationResult(
        before: YamlPackValidationReport.fromJson(
          Map<String, dynamic>.from(j['before'] as Map? ?? {}),
        ),
        after: YamlPackValidationReport.fromJson(
          Map<String, dynamic>.from(j['after'] as Map? ?? {}),
        ),
        fixed: [for (final f in j['fixed'] as List? ?? []) f.toString()],
      );
}
