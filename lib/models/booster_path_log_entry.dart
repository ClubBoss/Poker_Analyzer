class BoosterPathLogEntry {
  final String lessonId;
  final String tag;
  final DateTime shownAt;
  final DateTime? completedAt;

  const BoosterPathLogEntry({
    required this.lessonId,
    required this.tag,
    required this.shownAt,
    this.completedAt,
  });

  BoosterPathLogEntry copyWith({DateTime? completedAt}) {
    return BoosterPathLogEntry(
      lessonId: lessonId,
      tag: tag,
      shownAt: shownAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'lessonId': lessonId,
        'tag': tag,
        'shownAt': shownAt.toIso8601String(),
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      };

  factory BoosterPathLogEntry.fromJson(Map<String, dynamic> json) =>
      BoosterPathLogEntry(
        lessonId: json['lessonId'] as String? ?? '',
        tag: json['tag'] as String? ?? '',
        shownAt: DateTime.tryParse(json['shownAt'] as String? ?? '') ??
            DateTime.now(),
        completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
      );
}
