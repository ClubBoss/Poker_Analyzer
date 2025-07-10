import 'training_result.dart';

class TrainingSession {
  final DateTime date;
  final int total;
  final int correct;
  final double accuracy;
  final List<String> tags;
  final String? notes;
  final String? comment;
  final double? evDiff;
  final double? icmDiff;

  TrainingSession({
    required this.date,
    required this.total,
    required this.correct,
    required this.accuracy,
    List<String>? tags,
    this.notes,
    this.comment,
    this.evDiff,
    this.icmDiff,
  }) : tags = tags ?? const [];

  factory TrainingSession.fromJson(Map<String, dynamic> json) => TrainingSession(
        date: DateTime.parse(json['date'] as String),
        total: json['total'] as int? ?? 0,
        correct: json['correct'] as int? ?? 0,
        accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
        tags: [for (final t in (json['tags'] as List? ?? [])) t as String],
        notes: json['notes'] as String?,
        comment: json['comment'] as String?,
        evDiff: (json['evDiff'] as num?)?.toDouble(),
        icmDiff: (json['icmDiff'] as num?)?.toDouble(),
      );

  TrainingResult toTrainingResult() => TrainingResult(
        date: date,
        total: total,
        correct: correct,
        accuracy: accuracy,
        tags: tags,
        notes: notes,
        comment: comment,
        evDiff: evDiff,
        icmDiff: icmDiff,
      );

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'total': total,
        'correct': correct,
        'accuracy': accuracy,
        if (tags.isNotEmpty) 'tags': tags,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
        if (comment != null && comment!.isNotEmpty) 'comment': comment,
        if (evDiff != null) 'evDiff': evDiff,
        if (icmDiff != null) 'icmDiff': icmDiff,
      };
}
