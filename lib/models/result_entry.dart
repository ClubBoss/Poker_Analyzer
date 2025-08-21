import 'evaluation_result.dart';

class ResultEntry {
  final String name;
  final String userAction;
  final EvaluationResult evaluation;

  ResultEntry({
    required this.name,
    required this.userAction,
    required this.evaluation,
  });

  bool get correct => evaluation.correct;

  String get expected => evaluation.expectedAction;

  Map<String, dynamic> toJson() => {
        'name': name,
        'userAction': userAction,
        'evaluation': evaluation.toJson(),
      };

  factory ResultEntry.fromJson(Map<String, dynamic> json) => ResultEntry(
        name: json['name'] as String? ?? '',
        userAction: json['userAction'] as String? ?? '-',
        evaluation: EvaluationResult.fromJson(
          Map<String, dynamic>.from(json['evaluation'] as Map),
        ),
      );
}
