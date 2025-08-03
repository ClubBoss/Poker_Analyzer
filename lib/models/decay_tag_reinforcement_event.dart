import 'package:json_annotation/json_annotation.dart';

part 'decay_tag_reinforcement_event.g.dart';

@JsonSerializable()
class DecayTagReinforcementEvent {
  final String tag;
  final double delta;
  @JsonKey(fromJson: _dateFromJson, toJson: _dateToJson)
  final DateTime timestamp;

  DecayTagReinforcementEvent({
    required this.tag,
    required this.delta,
    required this.timestamp,
  });

  factory DecayTagReinforcementEvent.fromJson(Map<String, dynamic> json) =>
      _$DecayTagReinforcementEventFromJson(json);

  Map<String, dynamic> toJson() => _$DecayTagReinforcementEventToJson(this);

  static DateTime _dateFromJson(String? date) =>
      DateTime.tryParse(date ?? '') ?? DateTime.now();
  static String _dateToJson(DateTime date) => date.toIso8601String();
}
