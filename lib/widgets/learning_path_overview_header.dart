import 'package:flutter/material.dart';

class LearningPathOverviewHeader extends StatelessWidget {
  final int totalStages;
  final int completedStages;
  final int remainingPacks;
  final double avgMastery;
  final String? message;

  const LearningPathOverviewHeader({
    super.key,
    required this.totalStages,
    required this.completedStages,
    required this.remainingPacks,
    required this.avgMastery,
    this.message,
  });

  Color _masteryColor() {
    if (avgMastery >= 0.8) return Colors.green.shade700;
    if (avgMastery >= 0.5) return Colors.yellow.shade700;
    return Colors.red.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final progress = totalStages == 0 ? 0.0 : completedStages / totalStages;
    final barColor = progress >= 1.0
        ? Colors.green
        : progress > 0.0
            ? Colors.yellow
            : Colors.grey;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Пройдено $completedStages из $totalStages этапов',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(
                width: 80,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  minHeight: 6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: _masteryColor(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Средний навык: ${(avgMastery * 100).round()}%',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade700,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Осталось паков: $remainingPacks',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(message!, style: const TextStyle(color: Colors.white70)),
          ],
        ],
      ),
    );
  }
}
