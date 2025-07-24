import 'unlock_condition.dart';

class LearningPathStageModel {
  final String id;
  final String title;
  final String description;
  final String packId;
  final double requiredAccuracy;
  final int minHands;
  final List<String> unlocks;
  final List<String> unlockAfter;
  final List<String> tags;
  final int order;
  final bool isOptional;
  final UnlockCondition? unlockCondition;

  const LearningPathStageModel({
    required this.id,
    required this.title,
    required this.description,
    required this.packId,
    required this.requiredAccuracy,
    required this.minHands,
    List<String>? unlocks,
    List<String>? tags,
    List<String>? unlockAfter,
    this.order = 0,
    this.isOptional = false,
    this.unlockCondition,
  })  : unlocks = unlocks ?? const [],
        unlockAfter = unlockAfter ?? const [],
        tags = tags ?? const [];

  factory LearningPathStageModel.fromJson(Map<String, dynamic> json) {
    return LearningPathStageModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      packId: json['packId'] as String? ?? '',
      requiredAccuracy: (json['requiredAccuracy'] as num?)?.toDouble() ?? 0.0,
      minHands: (json['minHands'] as num?)?.toInt() ?? 0,
      unlocks: [for (final u in (json['unlocks'] as List? ?? [])) u.toString()],
      unlockAfter: [for (final u in (json['unlockAfter'] as List? ?? [])) u.toString()],
      tags: [for (final t in (json['tags'] as List? ?? [])) t.toString()],
      order: (json['order'] as num?)?.toInt() ?? 0,
      isOptional: json['isOptional'] as bool? ?? false,
      unlockCondition: json['unlockCondition'] is Map
          ? UnlockCondition.fromJson(
              Map<String, dynamic>.from(json['unlockCondition'] as Map))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'packId': packId,
        'requiredAccuracy': requiredAccuracy,
        'minHands': minHands,
        if (unlocks.isNotEmpty) 'unlocks': unlocks,
        if (unlockAfter.isNotEmpty) 'unlockAfter': unlockAfter,
        if (tags.isNotEmpty) 'tags': tags,
        'order': order,
        if (isOptional) 'isOptional': true,
        if (unlockCondition != null)
          'unlockCondition': unlockCondition!.toJson(),
      };

  factory LearningPathStageModel.fromYaml(Map yaml) {
    final map = <String, dynamic>{};
    yaml.forEach((k, v) => map[k.toString()] = v);
    return LearningPathStageModel.fromJson(map);
  }
}
