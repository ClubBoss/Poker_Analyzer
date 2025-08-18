// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_pack_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrainingPackTemplate _$TrainingPackTemplateFromJson(
        Map<String, dynamic> json) =>
    TrainingPackTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      gameType: json['gameType'] as String,
      category: json['category'] as String?,
      description: json['description'] as String,
      hands: (json['hands'] as List<dynamic>)
          .map((e) => SavedHand.fromJson(e as Map<String, dynamic>))
          .toList(),
      version: json['version'] as String? ?? '1.0.0',
      author: json['author'] as String? ?? '',
      revision: (json['revision'] as num?)?.toInt() ?? 1,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      defaultColor: json['defaultColor'] as String? ?? '#2196F3',
      pinned: json['pinned'] as bool? ?? false,
    );

Map<String, dynamic> _$TrainingPackTemplateToJson(
        TrainingPackTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'gameType': instance.gameType,
      'category': instance.category,
      'description': instance.description,
      'hands': instance.hands.map((e) => e.toJson()).toList(),
      'version': instance.version,
      'author': instance.author,
      'revision': instance.revision,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'isBuiltIn': instance.isBuiltIn,
      'tags': instance.tags,
      'defaultColor': instance.defaultColor,
      'pinned': instance.pinned,
    };
