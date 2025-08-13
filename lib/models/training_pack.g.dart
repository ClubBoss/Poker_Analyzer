part of 'training_pack.dart';

TrainingSessionResult _$TrainingSessionResultFromJson(
        Map<String, dynamic> json) =>
    TrainingSessionResult(
      date: DateTime.parse(json['date'] as String),
      total: json['total'] as int? ?? 0,
      correct: json['correct'] as int? ?? 0,
      tasks: const [],
    );

Map<String, dynamic> _$TrainingSessionResultToJson(
        TrainingSessionResult instance) =>
    <String, dynamic>{};

TrainingPack _$TrainingPackFromJson(Map<String, dynamic> json) => TrainingPack(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Uncategorized',
      gameType: GameType.cash,
      colorTag: json['colorTag'] as String? ?? '',
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
      tags: const [],
      hands: const [],
      spots: const [],
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
      history: const [],
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );

Map<String, dynamic> _$TrainingPackToJson(TrainingPack instance) =>
    <String, dynamic>{'createdAt': instance.createdAt.toIso8601String()};
