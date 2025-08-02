class PinnedLearningItem {
  final String type; // 'lesson' or 'pack'
  final String id;

  const PinnedLearningItem({required this.type, required this.id});

  factory PinnedLearningItem.fromJson(Map<String, dynamic> json) =>
      PinnedLearningItem(
        type: json['type'] as String? ?? '',
        id: json['id'] as String? ?? '',
      );

  Map<String, String> toJson() => {'type': type, 'id': id};
}
