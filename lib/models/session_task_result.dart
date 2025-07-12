import 'package:json_annotation/json_annotation.dart';

part 'session_task_result.g.dart';

@JsonSerializable()
class SessionTaskResult {
  final String question;
  final String selectedAnswer;
  final String correctAnswer;
  final bool correct;

  SessionTaskResult({
    required this.question,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.correct,
  });

  factory SessionTaskResult.fromJson(Map<String, dynamic> json) =>
      _$SessionTaskResultFromJson(json);
  Map<String, dynamic> toJson() => _$SessionTaskResultToJson(this);
}
