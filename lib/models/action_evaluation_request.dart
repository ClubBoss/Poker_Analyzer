/// Represents an action queued for evaluation by the analysis engine.
import 'package:uuid/uuid.dart';

class ActionEvaluationRequest {
  final String id;
  final int street;
  final int playerIndex;
  final String action;
  final int? amount;
  final Map<String, dynamic>? metadata;

  ActionEvaluationRequest({
    String? id,
    required this.street,
    required this.playerIndex,
    required this.action,
    this.amount,
    this.metadata,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'street': street,
        'playerIndex': playerIndex,
        'action': action,
        if (amount != null) 'amount': amount,
        if (metadata != null) 'metadata': metadata,
      };

  factory ActionEvaluationRequest.fromJson(Map<String, dynamic> json) {
    return ActionEvaluationRequest(
      id: json['id'] as String?,
      street: json['street'] as int? ?? 0,
      playerIndex: json['playerIndex'] as int? ?? 0,
      action: json['action'] as String? ?? '',
      amount: json['amount'] as int?,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
    );
  }
}

