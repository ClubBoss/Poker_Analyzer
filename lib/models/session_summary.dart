class SessionSummary {
  final DateTime date;
  final int total;
  final int correct;

  SessionSummary(
      {required this.date, required this.total, required this.correct});

  double get accuracy => total == 0 ? 0 : correct * 100 / total;

  factory SessionSummary.fromJson(Map<String, dynamic> json) {
    return SessionSummary(
      date: DateTime.parse(json['date'] as String),
      total: json['total'] as int? ?? 0,
      correct: json['correct'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'total': total,
        'correct': correct,
      };
}
