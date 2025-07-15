import 'saved_hand.dart';
import 'package:json_annotation/json_annotation.dart';

part 'training_pack_template.g.dart';

@JsonSerializable(explicitToJson: true)
class TrainingPackTemplate {
  final String id;
  final String name;
  final String gameType;
  final String? category;
  final String description;
  final List<SavedHand> hands;
  /// семантическая версия шаблона (major.minor.patch)
  final String version;
  /// имя или ник автора шаблона
  final String author;
  /// уникальная ревизия (монотонно увеличивается, служит для обновлений)
  final int revision;
  /// дата создания и последнего обновления
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isBuiltIn;
  final List<String> tags;
  final String defaultColor;
  bool pinned;

  TrainingPackTemplate({
    required this.id,
    required this.name,
    required this.gameType,
    this.category,
    required this.description,
    required this.hands,
    this.version = '1.0.0',
    this.author = '',
    this.revision = 1,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isBuiltIn = false,
    List<String>? tags,
    this.defaultColor = '#2196F3',
    this.pinned = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        tags = tags ?? const [];

  factory TrainingPackTemplate.fromJson(Map<String, dynamic> json) =>
      _$TrainingPackTemplateFromJson(json);
  Map<String, dynamic> toJson() => _$TrainingPackTemplateToJson(this);
}
