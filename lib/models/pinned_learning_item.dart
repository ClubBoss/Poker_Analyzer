class PinnedLearningItem {
  final String type; // 'lesson' or 'pack'
  final String id;
  final int? lastPosition;

  const PinnedLearningItem({
    required this.type,
    required this.id,
    this.lastPosition,
  });

  PinnedLearningItem copyWith({String? type, String? id, int? lastPosition}) =>
      PinnedLearningItem(
        type: type ?? this.type,
        id: id ?? this.id,
        lastPosition: lastPosition ?? this.lastPosition,
      );

  factory PinnedLearningItem.fromJson(Map<String, dynamic> json) =>
      PinnedLearningItem(
        type: json['type'] as String? ?? '',
        id: json['id'] as String? ?? '',
        lastPosition: json['lastPosition'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'id': id,
        if (lastPosition != null) 'lastPosition': lastPosition,
      };
}
