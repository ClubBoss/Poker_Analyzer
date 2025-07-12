import 'package:json_annotation/json_annotation.dart';

part 'training_pack_template_model.g.dart';

@JsonSerializable(explicitToJson: true)
class TrainingPackTemplateModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final int difficulty;
  final Map<String, dynamic> filters;
  final bool isTournament;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime? lastGeneratedAt;
  final double rating;

  int get difficultyLevel => difficulty;

  const TrainingPackTemplateModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.difficulty = 1,
    Map<String, dynamic>? filters,
    this.isTournament = false,
    this.isFavorite = false,
    DateTime? createdAt,
    this.lastGeneratedAt,
    this.rating = 0,
  })  : filters = filters ?? const {},
        createdAt = createdAt ?? DateTime.now();

  TrainingPackTemplateModel copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    int? difficulty,
    Map<String, dynamic>? filters,
    bool? isTournament,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? lastGeneratedAt,
    double? rating,
  }) {
    return TrainingPackTemplateModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      filters: filters ?? Map<String, dynamic>.from(this.filters),
      isTournament: isTournament ?? this.isTournament,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      lastGeneratedAt: lastGeneratedAt ?? this.lastGeneratedAt,
      rating: rating ?? this.rating,
    );
  }

  factory TrainingPackTemplateModel.fromJson(Map<String, dynamic> json) =>
      _$TrainingPackTemplateModelFromJson(json);

  Map<String, dynamic> toJson() => _$TrainingPackTemplateModelToJson(this);
}

