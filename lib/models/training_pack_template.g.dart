part of 'training_pack_template.dart';

TrainingPackTemplate _$TrainingPackTemplateFromJson(
  Map<String, dynamic> json,
) =>
    TrainingPackTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      gameType: json['gameType'] as String,
      category: json['category'] as String?,
      description: json['description'] as String,
      hands: const [],
      version: json['version'] as String? ?? '1.0.0',
      author: json['author'] as String? ?? '',
      revision: json['revision'] as int? ?? 1,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
      tags: const [],
      defaultColor: json['defaultColor'] as String? ?? '#2196F3',
      pinned: json['pinned'] as bool? ?? false,
    );

Map<String, dynamic> _$TrainingPackTemplateToJson(
  TrainingPackTemplate instance,
) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'gameType': instance.gameType,
      'category': instance.category,
      'description': instance.description,
      'version': instance.version,
      'author': instance.author,
      'revision': instance.revision,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'isBuiltIn': instance.isBuiltIn,
      'defaultColor': instance.defaultColor,
      'pinned': instance.pinned,
    };
