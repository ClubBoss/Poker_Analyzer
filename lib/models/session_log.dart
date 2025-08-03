
class SessionLog {
  final String sessionId;
  final String templateId;
  final DateTime startedAt;
  final DateTime completedAt;
  final int correctCount;
  final int mistakeCount;
  final double? evPercent;
  final Map<String, int> categories;
  final List<String> tags;

  SessionLog({
    required this.sessionId,
    required this.templateId,
    required this.startedAt,
    required this.completedAt,
    required this.correctCount,
    required this.mistakeCount,
    this.evPercent,
    Map<String, int>? categories,
    List<String>? tags,
  })  : categories = categories ?? const {},
        tags = tags ?? const [];

  factory SessionLog.fromJson(Map<String, dynamic> j) => SessionLog(
        sessionId: j['sessionId'] as String? ?? '',
        templateId: j['templateId'] as String? ?? '',
        startedAt:
            DateTime.tryParse(j['startedAt'] as String? ?? '') ?? DateTime.now(),
        completedAt:
            DateTime.tryParse(j['completedAt'] as String? ?? '') ?? DateTime.now(),
        correctCount: j['correct'] as int? ?? 0,
        mistakeCount: j['mistakes'] as int? ?? 0,
        evPercent: (j['evPercent'] as num?)?.toDouble(),
        categories: {
          for (final e in (j['categories'] as Map? ?? {}).entries)
            e.key as String: (e.value as num).toInt()
          },
        tags: [for (final t in (j['tags'] as List? ?? [])) t.toString()],
      );

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'templateId': templateId,
        'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt.toIso8601String(),
      'correct': correctCount,
      'mistakes': mistakeCount,
        if (evPercent != null) 'evPercent': evPercent,
        if (categories.isNotEmpty) 'categories': categories,
        if (tags.isNotEmpty) 'tags': tags,
      };
}
