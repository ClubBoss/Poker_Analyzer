// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_evaluation_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActionEvaluationRequest _$ActionEvaluationRequestFromJson(
        Map<String, dynamic> json) =>
    ActionEvaluationRequest(
      id: json['id'] as String?,
      street: (json['street'] as num).toInt(),
      playerIndex: (json['playerIndex'] as num).toInt(),
      action: json['action'] as String,
      amount: (json['amount'] as num?)?.toDouble(),
      metadata: json['metadata'] as Map<String, dynamic>?,
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ActionEvaluationRequestToJson(
        ActionEvaluationRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'street': instance.street,
      'playerIndex': instance.playerIndex,
      'action': instance.action,
      'amount': instance.amount,
      'metadata': instance.metadata,
      'attempts': instance.attempts,
    };
