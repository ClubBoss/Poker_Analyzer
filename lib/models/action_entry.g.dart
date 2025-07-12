// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActionEntry _$ActionEntryFromJson(Map<String, dynamic> json) => ActionEntry(
      (json['street'] as num).toInt(),
      (json['playerIndex'] as num).toInt(),
      json['action'] as String,
      amount: (json['amount'] as num?)?.toDouble(),
      generated: json['generated'] as bool? ?? false,
      manualEvaluation: json['manualEvaluation'] as String?,
      customLabel: json['customLabel'] as String?,
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
      potAfter: (json['potAfter'] as num?)?.toDouble() ?? 0,
      potOdds: (json['potOdds'] as num?)?.toDouble(),
      equity: (json['equity'] as num?)?.toDouble(),
      ev: (json['ev'] as num?)?.toDouble(),
      icmEv: (json['icmEv'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ActionEntryToJson(ActionEntry instance) =>
    <String, dynamic>{
      'street': instance.street,
      'playerIndex': instance.playerIndex,
      'action': instance.action,
      'amount': instance.amount,
      'generated': instance.generated,
      'manualEvaluation': instance.manualEvaluation,
      'customLabel': instance.customLabel,
      'potAfter': instance.potAfter,
      'potOdds': instance.potOdds,
      'equity': instance.equity,
      'ev': instance.ev,
      'icmEv': instance.icmEv,
      'timestamp': instance.timestamp.toIso8601String(),
    };
