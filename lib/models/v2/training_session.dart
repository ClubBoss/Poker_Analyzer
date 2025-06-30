class TrainingSession {
  final String id;
  final String templateId;
  DateTime startedAt;
  DateTime? completedAt;
  int index;
  final Map<String, bool> results;

  TrainingSession({
    required this.id,
    required this.templateId,
    DateTime? startedAt,
    this.completedAt,
    this.index = 0,
    Map<String, bool>? results,
  })  : startedAt = startedAt ?? DateTime.now(),
        results = results ?? {};

  factory TrainingSession.fromJson(Map<String, dynamic> j) => TrainingSession(
        id: j['id'] as String? ?? '',
        templateId: j['templateId'] as String? ?? '',
        startedAt:
            DateTime.tryParse(j['startedAt'] as String? ?? '') ?? DateTime.now(),
        completedAt: j['completedAt'] != null
            ? DateTime.tryParse(j['completedAt'])
            : null,
        index: j['index'] as int? ?? 0,
        results: j['results'] != null
            ? Map<String, bool>.from(j['results'] as Map)
            : {},
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'templateId': templateId,
        'startedAt': startedAt.toIso8601String(),
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
        'index': index,
        if (results.isNotEmpty) 'results': results,
      };
}
