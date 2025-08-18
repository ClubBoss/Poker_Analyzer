part of 'decay_tag_reinforcement_event.dart';

DecayTagReinforcementEvent _$DecayTagReinforcementEventFromJson(
  Map<String, dynamic> json,
) => DecayTagReinforcementEvent(
  tag: json['tag'] as String,
  delta: (json['delta'] as num).toDouble(),
  timestamp: DecayTagReinforcementEvent._dateFromJson(
    json['timestamp'] as String?,
  ),
);

Map<String, dynamic> _$DecayTagReinforcementEventToJson(
  DecayTagReinforcementEvent instance,
) => <String, dynamic>{
  'tag': instance.tag,
  'delta': instance.delta,
  'timestamp': DecayTagReinforcementEvent._dateToJson(instance.timestamp),
};
