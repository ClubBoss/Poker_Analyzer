import "result_entry.dart";

class CloudTrainingSession {
  final String path;
  final DateTime date;
  final List<ResultEntry> results;
  final String? comment;
  final Map<String, String>? handNotes;

  CloudTrainingSession({
    required this.path,
    required this.date,
    required this.results,
    this.comment,
    this.handNotes,
  });

  factory CloudTrainingSession.fromJson(Map<String, dynamic> json,
      {required String path}) {
    final results = <ResultEntry>[];
    final list = json['results'];
    if (list is List) {
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          results.add(ResultEntry.fromJson(item));
        }
      }
    }
    Map<String, String>? notes;
    final notesJson = json['handNotes'];
    if (notesJson is Map) {
      notes = <String, String>{};
      notesJson.forEach((key, value) {
        if (key is String && value is String) {
          notes![key] = value;
        }
      });
      if (notes.isEmpty) notes = null;
    }
    return CloudTrainingSession(
      path: path,
      date: DateTime.parse(json['date'] as String),
      results: results,
      comment: json['comment'] as String?,
      handNotes: notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'results': [for (final r in results) r.toJson()],
        if (comment != null && comment!.isNotEmpty) 'comment': comment,
        if (handNotes != null && handNotes!.isNotEmpty) 'handNotes': handNotes,
      };

  int get total => results.length;
  int get correct => results.where((r) => r.correct).length;
  int get mistakes => total - correct;
  double get accuracy => total == 0 ? 0 : correct * 100 / total;
}
