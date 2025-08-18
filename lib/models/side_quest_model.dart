class SideQuestModel {
  final String id;
  final String title;
  final String packId;
  final String type;

  const SideQuestModel({
    required this.id,
    required this.title,
    required this.packId,
    this.type = 'remedial',
  });

  factory SideQuestModel.fromJson(Map<String, dynamic> json) {
    return SideQuestModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      packId: json['packId'] as String? ?? '',
      type: json['type'] as String? ?? 'remedial',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'packId': packId,
    if (type.isNotEmpty) 'type': type,
  };

  factory SideQuestModel.fromYaml(Map yaml) {
    final map = <String, dynamic>{};
    yaml.forEach((k, v) => map[k.toString()] = v);
    return SideQuestModel.fromJson(map);
  }
}
