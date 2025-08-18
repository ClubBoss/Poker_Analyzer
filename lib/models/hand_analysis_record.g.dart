// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hand_analysis_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HandAnalysisRecord _$HandAnalysisRecordFromJson(Map<String, dynamic> json) =>
    HandAnalysisRecord(
      card1: json['card1'] as String,
      card2: json['card2'] as String,
      stack: (json['stack'] as num).toInt(),
      playerCount: (json['playerCount'] as num).toInt(),
      heroIndex: (json['heroIndex'] as num).toInt(),
      ev: (json['ev'] as num).toDouble(),
      icm: (json['icm'] as num).toDouble(),
      action: json['action'] as String,
      hint: json['hint'] as String,
      date: HandAnalysisRecord._dateFromJson(json['date'] as String?),
    );

Map<String, dynamic> _$HandAnalysisRecordToJson(HandAnalysisRecord instance) =>
    <String, dynamic>{
      'card1': instance.card1,
      'card2': instance.card2,
      'stack': instance.stack,
      'playerCount': instance.playerCount,
      'heroIndex': instance.heroIndex,
      'ev': instance.ev,
      'icm': instance.icm,
      'action': instance.action,
      'hint': instance.hint,
      'date': HandAnalysisRecord._dateToJson(instance.date),
    };
