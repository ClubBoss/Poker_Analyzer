import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/session_log_service.dart';
import '../screens/training_stats_screen.dart';

class TrainingProgressCard extends StatelessWidget {
  const TrainingProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    final logs = context.watch<SessionLogService>().logs;
    int totalHands = 0;
    int correctHands = 0;
    int totalMistakes = 0;
    int sessionsThisWeek = 0;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    for (final log in logs) {
      final hands = log.correctCount + log.mistakeCount;
      totalHands += hands;
      correctHands += log.correctCount;
      totalMistakes += log.mistakeCount;
      if (!log.completedAt.isBefore(weekStart)) {
        sessionsThisWeek++;
      }
    }
    final accuracy = totalHands > 0 ? correctHands / totalHands : 0.0;
    final accent = Theme.of(context).colorScheme.secondary;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TrainingStatsScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$totalHands hands trained',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: accuracy,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(accuracy * 100).toStringAsFixed(1)}% accuracy',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$totalMistakes mistakes',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                const Icon(Icons.calendar_today, color: Colors.amberAccent),
                const SizedBox(height: 4),
                Text(
                  '$sessionsThisWeek this week',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
