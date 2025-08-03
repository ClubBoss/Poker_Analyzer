import 'package:flutter/material.dart';
import '../services/session_log_service.dart';

/// Small chip displaying historical stats for a learning path stage.
class StageProgressChip extends StatelessWidget {
  final StageStats stats;

  const StageProgressChip({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final hands = stats.handsPlayed;
    final accuracy = stats.accuracy;
    final text = '$hands рук · ${accuracy.toStringAsFixed(0)}%';
    return Tooltip(
      message:
          'Средняя точность за всё время: ${accuracy.toStringAsFixed(0)}% ($hands рук)',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.black, fontSize: 12),
        ),
      ),
    );
  }
}
