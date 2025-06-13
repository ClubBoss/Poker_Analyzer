import 'package:flutter/material.dart';

import '../models/action_evaluation_request.dart';

class EvaluationRequestTile extends StatelessWidget {
  final ActionEvaluationRequest request;
  const EvaluationRequestTile({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final data = Map<String, dynamic>.from(request.toJson());
    final metadata = data.remove('metadata') as Map<String, dynamic>?;
    final extras = <String, dynamic>{
      if (metadata != null) ...metadata,
      ...data,
    }..removeWhere((key, value) =>
        key == 'playerIndex' ||
        key == 'street' ||
        key == 'action' ||
        key == 'amount');

    final expected = metadata?['expectedAction'] ?? data['expectedAction'];
    final feedback = metadata?['feedbackText'] ?? data['feedbackText'];

    return Card(
      child: ExpansionTile(
        title: Text(
          'Player ${request.playerIndex}, Street ${request.street}, '
          '${request.action}${request.amount != null ? ' ${request.amount}' : ''}',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('playerIndex: ${request.playerIndex}'),
                Text('street: ${request.street}'),
                Text('action: ${request.action}'),
                if (request.amount != null) Text('amount: ${request.amount}'),
                if (expected != null) Text('expectedAction: $expected'),
                if (feedback != null) Text('feedbackText: $feedback'),
                for (final entry in extras.entries)
                  Text('${entry.key}: ${entry.value}')
              ],
            ),
          ),
        ],
      ),
    );
  }
}
