import 'package:json_annotation/json_annotation.dart';
import 'copy_with_mixin.dart';

part 'training_pack_template_model.g.dart';

@JsonSerializable(explicitToJson: true)
class TrainingPackTemplateModel
    with CopyWithMixin<TrainingPackTemplateModel> {
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

  factory TrainingPackTemplateModel.fromJson(Map<String, dynamic> json) =>
      _$TrainingPackTemplateModelFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$TrainingPackTemplateModelToJson(this);

  @override
  TrainingPackTemplateModel Function(Map<String, dynamic> json) get fromJson =>
      TrainingPackTemplateModel.fromJson;
}

