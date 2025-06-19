class TrainingResult {
  final DateTime date;
  final int total;
  final int correct;
  final double accuracy;
  final List<String> tags;

  TrainingResult({
    required this.date,
    required this.total,
    required this.correct,
    required this.accuracy,
    List<String>? tags,
  }) : tags = tags ?? const [];

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'total': total,
        'correct': correct,
        'accuracy': accuracy,
        if (tags.isNotEmpty) 'tags': tags,
      };

  factory TrainingResult.fromJson(Map<String, dynamic> json) => TrainingResult(
        date: DateTime.parse(json['date'] as String),
        total: json['total'] as int? ?? 0,
        correct: json['correct'] as int? ?? 0,
        accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
        tags: [for (final t in (json['tags'] as List? ?? [])) t as String],
      );
}
