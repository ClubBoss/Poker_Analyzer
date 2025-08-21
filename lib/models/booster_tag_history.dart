class BoosterTagHistory {
  final String tag;
  final int shownCount;
  final int startedCount;
  final int completedCount;
  final DateTime lastInteraction;

  const BoosterTagHistory({
    required this.tag,
    required this.shownCount,
    required this.startedCount,
    required this.completedCount,
    required this.lastInteraction,
  });

  BoosterTagHistory copyWith({
    int? shownCount,
    int? startedCount,
    int? completedCount,
    DateTime? lastInteraction,
  }) {
    return BoosterTagHistory(
      tag: tag,
      shownCount: shownCount ?? this.shownCount,
      startedCount: startedCount ?? this.startedCount,
      completedCount: completedCount ?? this.completedCount,
      lastInteraction: lastInteraction ?? this.lastInteraction,
    );
  }

  Map<String, dynamic> toJson() => {
        'tag': tag,
        'shownCount': shownCount,
        'startedCount': startedCount,
        'completedCount': completedCount,
        'lastInteraction': lastInteraction.toIso8601String(),
      };

  factory BoosterTagHistory.fromJson(Map<String, dynamic> json) =>
      BoosterTagHistory(
        tag: json['tag'] as String? ?? '',
        shownCount: (json['shownCount'] as num?)?.toInt() ?? 0,
        startedCount: (json['startedCount'] as num?)?.toInt() ?? 0,
        completedCount: (json['completedCount'] as num?)?.toInt() ?? 0,
        lastInteraction:
            DateTime.tryParse(json['lastInteraction'] as String? ?? '') ??
                DateTime.now(),
      );
}
