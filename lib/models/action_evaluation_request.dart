/// Represents an action queued for evaluation by the analysis engine.
import 'package:uuid/uuid.dart';
import 'package:json_annotation/json_annotation.dart';

part 'action_evaluation_request.g.dart';

@JsonSerializable()
class ActionEvaluationRequest {
  final String id;
  final int street;
  final int playerIndex;
  final String action;
  final double? amount;
  final Map<String, dynamic>? metadata;
  int attempts;

  ActionEvaluationRequest({
    String? id,
    required this.street,
    required this.playerIndex,
    required this.action,
    this.amount,
    this.metadata,
    this.attempts = 0,
  }) : id = id ?? const Uuid().v4();

  factory ActionEvaluationRequest.fromJson(Map<String, dynamic> json) =>
      _$ActionEvaluationRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ActionEvaluationRequestToJson(this);
}
