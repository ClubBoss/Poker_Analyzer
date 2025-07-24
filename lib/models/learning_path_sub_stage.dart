class LearningPathSubStage {
  final String title;
  final String packId;
  final double? requiredAccuracy;
  final int? minHands;

  const LearningPathSubStage({
    required this.title,
    required this.packId,
    this.requiredAccuracy,
    this.minHands,
  });

  factory LearningPathSubStage.fromJson(Map<String, dynamic> json) {
    return LearningPathSubStage(
      title: json['title'] as String? ?? '',
      packId: json['packId'] as String? ?? '',
      requiredAccuracy: (json['requiredAccuracy'] as num?)?.toDouble(),
      minHands: (json['minHands'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'packId': packId,
        if (requiredAccuracy != null) 'requiredAccuracy': requiredAccuracy,
        if (minHands != null) 'minHands': minHands,
      };

  factory LearningPathSubStage.fromYaml(Map yaml) {
    final map = <String, dynamic>{};
    yaml.forEach((k, v) => map[k.toString()] = v);
    return LearningPathSubStage.fromJson(map);
  }
}
