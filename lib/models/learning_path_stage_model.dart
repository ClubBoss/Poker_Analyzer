class LearningPathStageModel {
  final String id;
  final String title;
  final String description;
  final String packId;
  final double requiredAccuracy;
  final int minHands;
  final List<String> unlocks;
  final List<String> tags;
  final int order;
  final bool isOptional;

  const LearningPathStageModel({
    required this.id,
    required this.title,
    required this.description,
    required this.packId,
    required this.requiredAccuracy,
    required this.minHands,
    List<String>? unlocks,
    List<String>? tags,
    this.order = 0,
    this.isOptional = false,
  })  : unlocks = unlocks ?? const [],
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
      tags: [for (final t in (json['tags'] as List? ?? [])) t.toString()],
      order: (json['order'] as num?)?.toInt() ?? 0,
      isOptional: json['isOptional'] as bool? ?? false,
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
        if (tags.isNotEmpty) 'tags': tags,
        'order': order,
        if (isOptional) 'isOptional': true,
      };

  factory LearningPathStageModel.fromYaml(Map yaml) {
    final map = <String, dynamic>{};
    yaml.forEach((k, v) => map[k.toString()] = v);
    return LearningPathStageModel.fromJson(map);
  }
}
