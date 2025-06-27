import 'saved_hand.dart';

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
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        tags = tags ?? const [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'gameType': gameType,
        if (category != null) 'category': category,
        'description': description,
        'hands': [for (final h in hands) h.toJson()],
        'version': version,
        'author': author,
        'revision': revision,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isBuiltIn': isBuiltIn,
        if (tags.isNotEmpty) 'tags': tags,
        'defaultColor': defaultColor,
      };

  factory TrainingPackTemplate.fromJson(Map<String, dynamic> json) {
    return TrainingPackTemplate(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      gameType: json['gameType'] as String? ?? 'Cash Game',
      category: json['category'] as String?,
      description: json['description'] as String? ?? '',
      hands: [
        for (final h in (json['hands'] as List? ?? []))
          SavedHand.fromJson(Map<String, dynamic>.from(h))
      ],
      version: json['version'] as String? ?? '1.0.0',
      author: json['author'] as String? ?? '',
      revision: json['revision'] as int? ?? 1,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
      tags: [for (final t in (json['tags'] as List? ?? [])) t as String],
      defaultColor: json['defaultColor'] as String? ?? '#2196F3',
    );
  }
}
