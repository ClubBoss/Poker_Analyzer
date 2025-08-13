part of 'training_result.dart';

TrainingResult _$TrainingResultFromJson(Map<String, dynamic> json) =>
    TrainingResult(
      date: DateTime.parse(json['date'] as String),
      total: json['total'] as int? ?? 0,
      correct: json['correct'] as int? ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      notes: json['notes'] as String?,
      comment: json['comment'] as String?,
      evDiff: (json['evDiff'] as num?)?.toDouble(),
      icmDiff: (json['icmDiff'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$TrainingResultToJson(TrainingResult instance) =>
    <String, dynamic>{};
