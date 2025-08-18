part of 'session_task_result.dart';

SessionTaskResult _$SessionTaskResultFromJson(Map<String, dynamic> json) =>
    SessionTaskResult(
      question: json['question'] as String? ?? '',
      selectedAnswer: json['selectedAnswer'] as String? ?? '',
      correctAnswer: json['correctAnswer'] as String? ?? '',
      correct: json['correct'] as bool? ?? false,
    );

Map<String, dynamic> _$SessionTaskResultToJson(SessionTaskResult instance) =>
    <String, dynamic>{};
