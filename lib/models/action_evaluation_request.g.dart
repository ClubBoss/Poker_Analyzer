part of 'action_evaluation_request.dart';

ActionEvaluationRequest _$ActionEvaluationRequestFromJson(
  Map<String, dynamic> json,
) => ActionEvaluationRequest(
  id: json['id'] as String?,
  street: json['street'] as int? ?? 0,
  playerIndex: json['playerIndex'] as int? ?? 0,
  action: json['action'] as String? ?? '',
  amount: (json['amount'] as num?)?.toDouble(),
  metadata: json['metadata'] == null
      ? null
      : Map<String, dynamic>.from(json['metadata'] as Map),
  attempts: json['attempts'] as int? ?? 0,
);

Map<String, dynamic> _$ActionEvaluationRequestToJson(
  ActionEvaluationRequest instance,
) => <String, dynamic>{
  'id': instance.id,
  'street': instance.street,
  'playerIndex': instance.playerIndex,
  'action': instance.action,
  if (instance.amount != null) 'amount': instance.amount,
  if (instance.metadata != null) 'metadata': instance.metadata,
  'attempts': instance.attempts,
};
