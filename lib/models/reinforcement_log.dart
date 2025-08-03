import 'package:json_annotation/json_annotation.dart';

part 'reinforcement_log.g.dart';

@JsonSerializable()
class ReinforcementLog {
  final String id;
  final String type;
  final String source;
  @JsonKey(fromJson: _dateFromJson, toJson: _dateToJson)
  final DateTime? timestamp;

  ReinforcementLog({
    required this.id,
    required this.type,
    required this.source,
    required this.timestamp,
  });

  factory ReinforcementLog.fromJson(Map<String, dynamic> json) =>
      _$ReinforcementLogFromJson(json);

  Map<String, dynamic> toJson() => _$ReinforcementLogToJson(this);

  static DateTime? _dateFromJson(String? date) => DateTime.tryParse(date ?? '');
  static String? _dateToJson(DateTime? date) => date?.toIso8601String();
}
