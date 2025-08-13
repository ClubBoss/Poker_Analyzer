import 'saved_hand.dart';
import 'package:json_annotation/json_annotation.dart';
import 'copy_with_mixin.dart';

part 'training_pack_template.g.dart';

@JsonSerializable(explicitToJson: true)
class TrainingPackTemplate with CopyWithMixin<TrainingPackTemplate> {
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
  @override
  Map<String, dynamic> toJson() => _$TrainingPackTemplateToJson(this);

  @override
  TrainingPackTemplate Function(Map<String, dynamic> json) get fromJson =>
      TrainingPackTemplate.fromJson;

  factory TrainingPackTemplate.fromMap(Map<String, dynamic> map) {
    return TrainingPackTemplate(
      id: map['id'].toString(),
      name: map['name'].toString(),
      gameType: map['gameType'].toString(),
      category: map['category'] as String?,
      description: map['description'].toString(),
      hands: [
        for (final h in (map['hands'] as List? ?? const []))
          SavedHand.fromJson(Map<String, dynamic>.from(h))
      ],
      version: map['version']?.toString() ?? '1.0.0',
      author: map['author']?.toString() ?? '',
      revision: (map['revision'] as num?)?.toInt() ?? 1,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      isBuiltIn: map['isBuiltIn'] == true,
      tags: [for (final t in (map['tags'] as List? ?? const [])) t.toString()],
      defaultColor: map['defaultColor']?.toString() ?? '#2196F3',
      pinned: map['pinned'] == true,
    );
  }
}
