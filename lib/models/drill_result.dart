import 'package:json_annotation/json_annotation.dart';

part 'drill_result.g.dart';

@JsonSerializable()
class DrillResult {
  final String templateId;
  final String templateName;
  @JsonKey(fromJson: _dateFromJson, toJson: _dateToJson)
  final DateTime date;
  final int total;
  final int correct;
  final double evLoss;
  @JsonKey(defaultValue: [])
  final List<String> wrongSpotIds;
  DrillResult({
    required this.templateId,
    required this.templateName,
    required this.date,
    required this.total,
    required this.correct,
    required this.evLoss,
    List<String>? wrongSpotIds,
  }) : wrongSpotIds = wrongSpotIds ?? [];

  factory DrillResult.fromJson(Map<String, dynamic> json) =>
      _$DrillResultFromJson(json);

  Map<String, dynamic> toJson() => _$DrillResultToJson(this);

  static DateTime _dateFromJson(String? date) =>
      DateTime.tryParse(date ?? '') ?? DateTime.now();
  static String _dateToJson(DateTime date) => date.toIso8601String();
}
