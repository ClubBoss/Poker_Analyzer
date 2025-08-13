import 'learning_path_stage_model.dart';
import 'learning_track_section_model.dart';
import 'path_difficulty.dart';

class LearningPathTemplateV2 {
  final String id;
  final String title;
  final String description;
  final List<LearningPathStageModel> stages;
  final List<LearningTrackSectionModel> sections;
  final List<String> tags;
  final String? recommendedFor;
  final List<String> prerequisitePathIds;
  final String? coverAsset;
  final PathDifficulty? difficulty;
  final Map<String, dynamic>? composerMeta;

  const LearningPathTemplateV2({
    required this.id,
    required this.title,
    required this.description,
    List<LearningPathStageModel>? stages,
    List<LearningTrackSectionModel>? sections,
    List<String>? tags,
    this.recommendedFor,
    List<String>? prerequisitePathIds,
    this.coverAsset,
    this.difficulty,
    this.composerMeta,
  })  : stages = stages ?? const [],
        sections = sections ?? const [],
        tags = tags ?? const [],
        prerequisitePathIds = prerequisitePathIds ?? const [];

  List<LearningPathStageModel> get entryStages {
    final unlockedIds = <String>{};
    for (final s in stages) {
      unlockedIds.addAll(s.unlocks);
    }
    return [
      for (final s in stages)
        if (!unlockedIds.contains(s.id)) s
    ];
  }

  int get packCount => {for (final s in stages) s.packId}.length;

  factory LearningPathTemplateV2.fromJson(Map<String, dynamic> json) {
    return LearningPathTemplateV2(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      stages: [
        for (final s in (json['stages'] as List? ?? []))
          LearningPathStageModel.fromJson(Map<String, dynamic>.from(s)),
      ],
      sections: [
        for (final s in (json['sections'] as List? ?? []))
          LearningTrackSectionModel.fromJson(
            Map<String, dynamic>.from(s),
          ),
      ],
      tags: [for (final t in (json['tags'] as List? ?? [])) t.toString()],
      recommendedFor: json['recommendedFor'] as String?,
      coverAsset: json['cover'] as String?,
      difficulty: _parseDifficulty(json['difficulty']),
      prerequisitePathIds: [
        for (final id in (json['prerequisitePathIds'] as List? ?? []))
          id.toString()
      ],
      composerMeta: json['composerMeta'] is Map
          ? Map<String, dynamic>.from(json['composerMeta'])
          : null,
    );
  }

  static PathDifficulty? _parseDifficulty(dynamic value) {
    final s = value?.toString();
    switch (s) {
      case 'easy':
        return PathDifficulty.easy;
      case 'medium':
        return PathDifficulty.medium;
      case 'hard':
        return PathDifficulty.hard;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        if (stages.isNotEmpty) 'stages': [for (final s in stages) s.toJson()],
        if (sections.isNotEmpty)
          'sections': [for (final s in sections) s.toJson()],
        if (tags.isNotEmpty) 'tags': tags,
        if (recommendedFor != null) 'recommendedFor': recommendedFor,
        if (coverAsset != null) 'cover': coverAsset,
        if (difficulty != null) 'difficulty': difficulty!.name,
        if (composerMeta != null) 'composerMeta': composerMeta,
        if (prerequisitePathIds.isNotEmpty)
          'prerequisitePathIds': prerequisitePathIds,
      };

  factory LearningPathTemplateV2.fromYaml(Map yaml) {
    final map = <String, dynamic>{};
    yaml.forEach((k, v) => map[k.toString()] = v);
    return LearningPathTemplateV2.fromJson(map);
  }
}
