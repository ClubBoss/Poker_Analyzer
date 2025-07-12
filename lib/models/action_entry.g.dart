part of 'action_entry.dart';

ActionEntry _$ActionEntryFromJson(Map<String, dynamic> json) => ActionEntry(
      json['street'] as int? ?? 0,
      json['playerIndex'] as int? ?? 0,
      json['action'] as String? ?? '',
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
      if (instance.amount != null) 'amount': instance.amount,
      'generated': instance.generated,
      'timestamp': instance.timestamp.toIso8601String(),
      if (instance.manualEvaluation != null)
        'manualEvaluation': instance.manualEvaluation,
      if (instance.customLabel != null) 'customLabel': instance.customLabel,
      'potAfter': instance.potAfter,
      if (instance.potOdds != null) 'potOdds': instance.potOdds,
      if (instance.equity != null) 'equity': instance.equity,
      if (instance.ev != null) 'ev': instance.ev,
      if (instance.icmEv != null) 'icmEv': instance.icmEv,
    };
