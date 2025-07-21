import "learning_path_stage_model.dart";
class LearningPathTemplateV2 {
  final String id;
  final String title;
  final String description;
  final List<LearningPathStageModel> stages;
  final List<String> tags;
  final String? recommendedFor;

  const LearningPathTemplateV2({
    required this.id,
    required this.title,
    required this.description,
    List<LearningPathStageModel>? stages,
    List<String>? tags,
    this.recommendedFor,
  })  : stages = stages ?? const [],
        tags = tags ?? const [];

  List<LearningPathStageModel> get entryStages {
    final unlockedIds = <String>{};
    for (final s in stages) {
      unlockedIds.addAll(s.unlocks);
    }
    return [for (final s in stages) if (!unlockedIds.contains(s.id)) s];
  }

  factory LearningPathTemplateV2.fromJson(Map<String, dynamic> json) {
    return LearningPathTemplateV2(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      stages: [
        for (final s in (json['stages'] as List? ?? []))
          LearningPathStageModel.fromJson(Map<String, dynamic>.from(s)),
      ],
      tags: [for (final t in (json['tags'] as List? ?? [])) t.toString()],
      recommendedFor: json['recommendedFor'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        if (stages.isNotEmpty) 'stages': [for (final s in stages) s.toJson()],
        if (tags.isNotEmpty) 'tags': tags,
        if (recommendedFor != null) 'recommendedFor': recommendedFor,
      };

  factory LearningPathTemplateV2.fromYaml(Map yaml) {
    final map = <String, dynamic>{};
    yaml.forEach((k, v) => map[k.toString()] = v);
    return LearningPathTemplateV2.fromJson(map);
  }
}
