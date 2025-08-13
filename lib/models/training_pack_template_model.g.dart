part of 'training_pack_template_model.dart';

TrainingPackTemplateModel _$TrainingPackTemplateModelFromJson(
        Map<String, dynamic> json) =>
    TrainingPackTemplateModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
      filters: json['filters'] as Map<String, dynamic>? ?? const {},
      isTournament: json['isTournament'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastGeneratedAt: json['lastGeneratedAt'] == null
          ? null
          : DateTime.parse(json['lastGeneratedAt'] as String),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$TrainingPackTemplateModelToJson(
        TrainingPackTemplateModel instance) =>
    <String, dynamic>{};
