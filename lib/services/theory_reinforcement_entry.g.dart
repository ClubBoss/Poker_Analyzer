// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theory_reinforcement_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TheoryReinforcementEntry _$TheoryReinforcementEntryFromJson(
  Map<String, dynamic> json,
) =>
    TheoryReinforcementEntry(
      level: (json['level'] as num).toInt(),
      next: DateTime.parse(json['next'] as String),
    );

Map<String, dynamic> _$TheoryReinforcementEntryToJson(
  TheoryReinforcementEntry instance,
) =>
    <String, dynamic>{
      'level': instance.level,
      'next': instance.next.toIso8601String(),
    };
