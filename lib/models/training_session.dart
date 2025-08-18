import 'training_result.dart';
import 'package:json_annotation/json_annotation.dart';

part 'training_session.g.dart';

@JsonSerializable(explicitToJson: true)
class TrainingSession {
  final DateTime date;
  final int total;
  final int correct;
  final double accuracy;
  final List<String> tags;
  final String? notes;
  final String? comment;
  final double? evDiff;
  final double? icmDiff;

  TrainingSession({
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

  factory TrainingSession.fromJson(Map<String, dynamic> json) =>
      _$TrainingSessionFromJson(json);

  TrainingResult toTrainingResult() => TrainingResult(
    date: date,
    total: total,
    correct: correct,
    accuracy: accuracy,
    tags: tags,
    notes: notes,
    comment: comment,
    evDiff: evDiff,
    icmDiff: icmDiff,
  );

  Map<String, dynamic> toJson() => _$TrainingSessionToJson(this);
}
