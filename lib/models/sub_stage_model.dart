class SubStageModel {
  final String id;
  final String title;
  final String description;
  final int minHands;
  final double requiredAccuracy;

  const SubStageModel({
    required this.id,
    required this.title,
    this.description = '',
    this.minHands = 0,
    this.requiredAccuracy = 0,
  });

  factory SubStageModel.fromJson(Map<String, dynamic> json) {
    return SubStageModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      minHands: (json['minHands'] as num?)?.toInt() ?? 0,
      requiredAccuracy: (json['requiredAccuracy'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (description.isNotEmpty) 'description': description,
        if (minHands > 0) 'minHands': minHands,
        if (requiredAccuracy > 0) 'requiredAccuracy': requiredAccuracy,
      };

  factory SubStageModel.fromYaml(Map yaml) {
    final map = <String, dynamic>{};
    yaml.forEach((k, v) => map[k.toString()] = v);
    return SubStageModel.fromJson(map);
  }
}
