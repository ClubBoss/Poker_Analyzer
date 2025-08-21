class LearningTrackSectionModel {
  final String id;
  final String title;
  final String description;
  final List<String> stageIds;

  const LearningTrackSectionModel({
    required this.id,
    required this.title,
    required this.description,
    List<String>? stageIds,
  }) : stageIds = stageIds ?? const [];

  factory LearningTrackSectionModel.fromJson(Map<String, dynamic> json) {
    return LearningTrackSectionModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      stageIds: [
        for (final s in (json['stageIds'] as List? ?? [])) s.toString(),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    if (stageIds.isNotEmpty) 'stageIds': stageIds,
  };

  factory LearningTrackSectionModel.fromYaml(Map yaml) {
    final map = <String, dynamic>{};
    yaml.forEach((k, v) => map[k.toString()] = v);
    return LearningTrackSectionModel.fromJson(map);
  }
}
