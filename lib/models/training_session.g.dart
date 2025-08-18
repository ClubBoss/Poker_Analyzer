// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrainingSession _$TrainingSessionFromJson(Map<String, dynamic> json) =>
    TrainingSession(
      date: DateTime.parse(json['date'] as String),
      total: (json['total'] as num).toInt(),
      correct: (json['correct'] as num).toInt(),
      accuracy: (json['accuracy'] as num).toDouble(),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      notes: json['notes'] as String?,
      comment: json['comment'] as String?,
      evDiff: (json['evDiff'] as num?)?.toDouble(),
      icmDiff: (json['icmDiff'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$TrainingSessionToJson(TrainingSession instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'total': instance.total,
      'correct': instance.correct,
      'accuracy': instance.accuracy,
      'tags': instance.tags,
      'notes': instance.notes,
      'comment': instance.comment,
      'evDiff': instance.evDiff,
      'icmDiff': instance.icmDiff,
    };
