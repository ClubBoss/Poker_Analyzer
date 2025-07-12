import 'package:json_annotation/json_annotation.dart';

part 'training_result.g.dart';

@JsonSerializable(explicitToJson: true)
class TrainingResult {
  final DateTime date;
  final int total;
  final int correct;
  final double accuracy;
  final List<String> tags;
  final String? notes;
  final String? comment;
  final double? evDiff;
  final double? icmDiff;

  TrainingResult({
    required this.date,
    required this.total,
    required this.correct,
    required this.accuracy,
    List<String>? tags,
    this.notes,
    this.comment,
    this.evDiff,
    this.icmDiff,
  }) : tags = tags ?? const [];

  factory TrainingResult.fromJson(Map<String, dynamic> json) =>
      _$TrainingResultFromJson(json);
  Map<String, dynamic> toJson() => _$TrainingResultToJson(this);
}
