
class SessionLog {
  final String sessionId;
  final String templateId;
  final DateTime startedAt;
  final DateTime completedAt;
  final int correctCount;
  final int mistakeCount;
  final double? evPercent;
  final double? accuracyBefore;
  final double? accuracyAfter;
  final int? handsBefore;
  final int? handsAfter;
  final bool? unlockGoalReached;
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
    this.accuracyBefore,
    this.accuracyAfter,
    this.handsBefore,
    this.handsAfter,
    this.unlockGoalReached,
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
        accuracyBefore: (j['accuracyBefore'] as num?)?.toDouble(),
        accuracyAfter: (j['accuracyAfter'] as num?)?.toDouble(),
        handsBefore: (j['handsBefore'] as num?)?.toInt(),
        handsAfter: (j['handsAfter'] as num?)?.toInt(),
        unlockGoalReached: j['unlockGoalReached'] as bool?,
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
        if (accuracyBefore != null) 'accuracyBefore': accuracyBefore,
        if (accuracyAfter != null) 'accuracyAfter': accuracyAfter,
        if (handsBefore != null) 'handsBefore': handsBefore,
        if (handsAfter != null) 'handsAfter': handsAfter,
        if (unlockGoalReached != null)
          'unlockGoalReached': unlockGoalReached,
        if (categories.isNotEmpty) 'categories': categories,
        if (tags.isNotEmpty) 'tags': tags,
      };
}
