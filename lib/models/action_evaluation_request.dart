/// Represents an action queued for evaluation by the analysis engine.
import 'package:uuid/uuid.dart';

class ActionEvaluationRequest {
  final String id;
  final int street;
  final int playerIndex;
  final String action;
  final int? amount;
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'street': street,
        'playerIndex': playerIndex,
        'action': action,
        if (amount != null) 'amount': amount,
        if (metadata != null) 'metadata': metadata,
        'attempts': attempts,
      };

  factory ActionEvaluationRequest.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    return ActionEvaluationRequest(
      id: id ?? const Uuid().v4(),
      street: json['street'] as int? ?? 0,
      playerIndex: json['playerIndex'] as int? ?? 0,
      action: json['action'] as String? ?? '',
      amount: json['amount'] as int?,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      attempts: json['attempts'] as int? ?? 0,
    );
  }
}

