// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_task_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionTaskResult _$SessionTaskResultFromJson(Map<String, dynamic> json) =>
    SessionTaskResult(
      question: json['question'] as String,
      selectedAnswer: json['selectedAnswer'] as String,
      correctAnswer: json['correctAnswer'] as String,
      correct: json['correct'] as bool,
    );

Map<String, dynamic> _$SessionTaskResultToJson(SessionTaskResult instance) =>
    <String, dynamic>{
      'question': instance.question,
      'selectedAnswer': instance.selectedAnswer,
      'correctAnswer': instance.correctAnswer,
      'correct': instance.correct,
    };
