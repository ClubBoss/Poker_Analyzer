class TheoryGoal {
  final String title;
  final String description;
  final String tagOrCluster;
  final double targetProgress;

  const TheoryGoal({
    required this.title,
    required this.description,
    required this.tagOrCluster,
    required this.targetProgress,
  });

  factory TheoryGoal.fromJson(Map<String, dynamic> json) => TheoryGoal(
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    tagOrCluster:
        json['tag'] as String? ?? json['tagOrCluster'] as String? ?? '',
    targetProgress:
        (json['target'] as num?)?.toDouble() ??
        (json['targetProgress'] as num?)?.toDouble() ??
        0.0,
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'tag': tagOrCluster,
    'target': targetProgress,
  };
}
