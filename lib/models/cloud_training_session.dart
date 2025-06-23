import "result_entry.dart";

class CloudTrainingSession {
  final DateTime date;
  final List<ResultEntry> results;

  CloudTrainingSession({required this.date, required this.results});

  int get total => results.length;
  int get correct => results.where((r) => r.correct).length;
  int get mistakes => total - correct;
  double get accuracy => total == 0 ? 0 : correct * 100 / total;
}
