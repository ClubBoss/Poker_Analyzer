import "result_entry.dart";

class CloudTrainingSession {
  final DateTime date;
  final List<ResultEntry> results;
  final String? comment;

  CloudTrainingSession({
    required this.date,
    required this.results,
    this.comment,
  });

  factory CloudTrainingSession.fromJson(Map<String, dynamic> json) {
    final results = <ResultEntry>[];
    final list = json['results'];
    if (list is List) {
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          results.add(ResultEntry.fromJson(item));
        }
      }
    }
    return CloudTrainingSession(
      date: DateTime.parse(json['date'] as String),
      results: results,
      comment: json['comment'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'results': [for (final r in results) r.toJson()],
        if (comment != null && comment!.isNotEmpty) 'comment': comment,
      };

  int get total => results.length;
  int get correct => results.where((r) => r.correct).length;
  int get mistakes => total - correct;
  double get accuracy => total == 0 ? 0 : correct * 100 / total;
}
