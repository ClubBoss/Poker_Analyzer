import 'package:flutter/material.dart';
import '../models/session_log.dart';

/// Small chip showing progress for a learning path stage.
class StageProgressChip extends StatelessWidget {
  final SessionLog? log;
  final double requiredAccuracy;
  final int requiredHands;

  const StageProgressChip({
    super.key,
    required this.log,
    required this.requiredAccuracy,
    required this.requiredHands,
  });

  @override
  Widget build(BuildContext context) {
    final hands = (log?.correctCount ?? 0) + (log?.mistakeCount ?? 0);
    final correct = log?.correctCount ?? 0;
    final accuracy = hands == 0 ? 0.0 : correct / hands * 100;
    final completed =
        hands >= requiredHands && accuracy >= requiredAccuracy;

    Color color;
    if (completed) {
      color = Colors.green;
    } else if (hands > 0) {
      color = Colors.yellow.shade700;
    } else {
      color = Colors.grey;
    }

    final text = '$hands/$requiredHands · ${accuracy.toStringAsFixed(0)}%';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(color: Colors.black, fontSize: 12),
          ),
          if (completed) ...[
            const SizedBox(width: 4),
            const Text('✅', style: TextStyle(fontSize: 12)),
          ],
        ],
      ),
    );
  }
}
