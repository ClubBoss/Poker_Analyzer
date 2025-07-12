// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_pack_template_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrainingPackTemplateModel _$TrainingPackTemplateModelFromJson(
        Map<String, dynamic> json) =>
    TrainingPackTemplateModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
      filters: json['filters'] as Map<String, dynamic>?,
      isTournament: json['isTournament'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      lastGeneratedAt: json['lastGeneratedAt'] == null
          ? null
          : DateTime.parse(json['lastGeneratedAt'] as String),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$TrainingPackTemplateModelToJson(
        TrainingPackTemplateModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'category': instance.category,
      'difficulty': instance.difficulty,
      'filters': instance.filters,
      'isTournament': instance.isTournament,
      'isFavorite': instance.isFavorite,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastGeneratedAt': instance.lastGeneratedAt?.toIso8601String(),
      'rating': instance.rating,
    };
