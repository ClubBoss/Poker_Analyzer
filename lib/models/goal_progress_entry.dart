class GoalProgressEntry {
  final DateTime date;
  final int progress;

  GoalProgressEntry({required this.date, required this.progress});

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'progress': progress,
  };

  factory GoalProgressEntry.fromJson(Map<String, dynamic> json) =>
      GoalProgressEntry(
        date:
            DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        progress: json['progress'] as int? ?? 0,
      );
}
