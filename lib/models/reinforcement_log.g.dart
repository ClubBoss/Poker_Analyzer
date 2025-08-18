// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reinforcement_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReinforcementLog _$ReinforcementLogFromJson(Map<String, dynamic> json) =>
    ReinforcementLog(
      id: json['id'] as String,
      type: json['type'] as String,
      source: json['source'] as String,
      timestamp: ReinforcementLog._dateFromJson(json['timestamp'] as String?),
    );

Map<String, dynamic> _$ReinforcementLogToJson(ReinforcementLog instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'source': instance.source,
      'timestamp': ReinforcementLog._dateToJson(instance.timestamp),
    };
