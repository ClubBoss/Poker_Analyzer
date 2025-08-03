import 'package:json_annotation/json_annotation.dart';

part 'training_attempt.g.dart';

@JsonSerializable()
class TrainingAttempt {
  final String packId;
  final String spotId;
  @JsonKey(fromJson: _dateFromJson, toJson: _dateToJson)
  final DateTime timestamp;
  final double accuracy;
  final double ev;
  final double icm;

  TrainingAttempt({
    required this.packId,
    required this.spotId,
    required this.timestamp,
    required this.accuracy,
    required this.ev,
    required this.icm,
  });

  factory TrainingAttempt.fromJson(Map<String, dynamic> json) =>
      _$TrainingAttemptFromJson(json);

  Map<String, dynamic> toJson() => _$TrainingAttemptToJson(this);

  static DateTime _dateFromJson(String? date) =>
      DateTime.tryParse(date ?? '') ?? DateTime.now();
  static String _dateToJson(DateTime date) => date.toIso8601String();
}
