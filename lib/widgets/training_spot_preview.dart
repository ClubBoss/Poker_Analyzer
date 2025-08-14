import 'package:flutter/material.dart';

import '../models/training_spot.dart';
import '../models/action_entry.dart';

/// Displays a simplified preview of a [TrainingSpot].
///
/// Shows each player action and, if available, a label with strategy advice
/// ("PUSH", "CALL", "FOLD") below the action text.
class TrainingSpotPreview extends StatelessWidget {
  final TrainingSpot spot;

  const TrainingSpotPreview({super.key, required this.spot});

  Color? _colorForAdvice(String advice) {
    switch (advice.toUpperCase()) {
      case 'PUSH':
        return Colors.green;
      case 'FOLD':
        return Colors.red;
      case 'CALL':
        return Colors.blue;
      default:
        return null;
    }
  }

  Widget _buildAction(ActionEntry entry) {
    String label = entry.action;
    if (entry.amount != null) {
      label += ' ${entry.amount}';
    }

    if (entry.playerIndex < spot.stacks.length) {
      final stack = spot.stacks[entry.playerIndex];
      final bb = (stack / 12.5).round();
      label += ' $stack ($bb BB)';
    }

    String? advice;
    if (spot.strategyAdvice != null &&
        entry.playerIndex < spot.strategyAdvice!.length) {
      advice = spot.strategyAdvice![entry.playerIndex];
    }

    final adviceColor = advice != null ? _colorForAdvice(advice) : null;

    double? equity;
    if (spot.equities != null && entry.playerIndex < spot.equities!.length) {
      equity = spot.equities![entry.playerIndex].toDouble();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('P${entry.playerIndex + 1}: $label'),
            if (equity != null)
              Text(
                ' - ${equity.round()}%',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
          ],
        ),
        if (advice != null && adviceColor != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              advice.toUpperCase(),
              style: TextStyle(
                color: adviceColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final a in spot.actions) _buildAction(a),
      ],
    );
  }
}
