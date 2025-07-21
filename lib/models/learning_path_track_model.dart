class LearningPathTrackModel {
  final String id;
  final String title;
  final String description;
  final List<String> pathIds;
  final String? recommendedFor;
  final int order;

  const LearningPathTrackModel({
    required this.id,
    required this.title,
    required this.description,
    List<String>? pathIds,
    this.recommendedFor,
    this.order = 0,
  }) : pathIds = pathIds ?? const [];

  factory LearningPathTrackModel.fromJson(Map<String, dynamic> json) {
    return LearningPathTrackModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      pathIds: [for (final p in (json['pathIds'] as List? ?? [])) p.toString()],
      recommendedFor: json['recommendedFor'] as String?,
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    if (pathIds.isNotEmpty) 'pathIds': pathIds,
    if (recommendedFor != null) 'recommendedFor': recommendedFor,
    'order': order,
  };

  factory LearningPathTrackModel.fromYaml(Map yaml) {
    final map = <String, dynamic>{};
    yaml.forEach((k, v) => map[k.toString()] = v);
    return LearningPathTrackModel.fromJson(map);
  }
}
