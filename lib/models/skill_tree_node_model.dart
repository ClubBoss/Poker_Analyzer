class SkillTreeNodeModel {
  final String id;
  final String title;
  final String category;
  final List<String> prerequisites;
  final List<String> unlockedNodeIds;
  final String trainingPackId;
  final String theoryLessonId;
  final int level;
  final bool isCompleted;

  const SkillTreeNodeModel({
    required this.id,
    required this.title,
    required this.category,
    List<String>? prerequisites,
    List<String>? unlockedNodeIds,
    this.trainingPackId = '',
    this.theoryLessonId = '',
    this.level = 0,
    this.isCompleted = false,
  }) : prerequisites = prerequisites ?? const [],
       unlockedNodeIds = unlockedNodeIds ?? const [];

  factory SkillTreeNodeModel.fromJson(Map<String, dynamic> json) {
    return SkillTreeNodeModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? '',
      prerequisites: [
        for (final p in (json['prerequisites'] as List? ?? [])) p.toString(),
      ],
      unlockedNodeIds: [
        for (final u in (json['unlockedNodeIds'] as List? ?? [])) u.toString(),
      ],
      trainingPackId: json['trainingPackId'] as String? ?? '',
      theoryLessonId: json['theoryLessonId'] as String? ?? '',
      level: (json['level'] as num?)?.toInt() ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    if (prerequisites.isNotEmpty) 'prerequisites': prerequisites,
    if (unlockedNodeIds.isNotEmpty) 'unlockedNodeIds': unlockedNodeIds,
    'trainingPackId': trainingPackId,
    'theoryLessonId': theoryLessonId,
    'level': level,
    if (isCompleted) 'isCompleted': true,
  };

  factory SkillTreeNodeModel.fromYaml(Map yaml) {
    final map = <String, dynamic>{};
    yaml.forEach((k, v) => map[k.toString()] = v);
    return SkillTreeNodeModel.fromJson(map);
  }
}
