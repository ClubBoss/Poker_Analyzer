class PinnedLearningItem {
  final String type; // 'lesson', 'pack', or 'block'
  final String id;
  final int? lastPosition;
  final int? lastSeen;
  final int openCount;

  const PinnedLearningItem({
    required this.type,
    required this.id,
    this.lastPosition,
    this.lastSeen,
    this.openCount = 0,
  });

  PinnedLearningItem copyWith({
    String? type,
    String? id,
    int? lastPosition,
    int? lastSeen,
    int? openCount,
  }) => PinnedLearningItem(
    type: type ?? this.type,
    id: id ?? this.id,
    lastPosition: lastPosition ?? this.lastPosition,
    lastSeen: lastSeen ?? this.lastSeen,
    openCount: openCount ?? this.openCount,
  );

  factory PinnedLearningItem.fromJson(Map<String, dynamic> json) =>
      PinnedLearningItem(
        type: json['type'] as String? ?? '',
        id: json['id'] as String? ?? '',
        lastPosition: json['lastPosition'] as int?,
        lastSeen: json['lastSeen'] as int?,
        openCount: json['openCount'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'type': type,
    'id': id,
    if (lastPosition != null) 'lastPosition': lastPosition,
    if (lastSeen != null) 'lastSeen': lastSeen,
    'openCount': openCount,
  };
}
