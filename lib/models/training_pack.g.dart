// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_pack.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrainingSessionResult _$TrainingSessionResultFromJson(
        Map<String, dynamic> json) =>
    TrainingSessionResult(
      date: DateTime.parse(json['date'] as String),
      total: (json['total'] as num).toInt(),
      correct: (json['correct'] as num).toInt(),
      tasks: (json['tasks'] as List<dynamic>?)
          ?.map((e) => SessionTaskResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TrainingSessionResultToJson(
        TrainingSessionResult instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'total': instance.total,
      'correct': instance.correct,
      'tasks': instance.tasks.map((e) => e.toJson()).toList(),
    };

TrainingPack _$TrainingPackFromJson(Map<String, dynamic> json) => TrainingPack(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String? ?? 'Uncategorized',
      gameType: json['gameType'] == null
          ? GameType.cash
          : parseGameType(json['gameType']),
      colorTag: json['colorTag'] as String? ?? '#2196F3',
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      hands: (json['hands'] as List<dynamic>)
          .map((e) => SavedHand.fromJson(e as Map<String, dynamic>))
          .toList(),
      spots: (json['spots'] as List<dynamic>?)
          ?.map((e) => TrainingSpot.fromJson(e as Map<String, dynamic>))
          .toList(),
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
      history: (json['history'] as List<dynamic>?)
          ?.map(
              (e) => TrainingSessionResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TrainingPackToJson(TrainingPack instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'category': instance.category,
      'gameType': _gameTypeToJson(instance.gameType),
      'colorTag': instance.colorTag,
      'isBuiltIn': instance.isBuiltIn,
      'tags': instance.tags,
      'hands': instance.hands.map((e) => e.toJson()).toList(),
      'spots': instance.spots.map((e) => e.toJson()).toList(),
      'difficulty': instance.difficulty,
      'history': instance.history.map((e) => e.toJson()).toList(),
    };
