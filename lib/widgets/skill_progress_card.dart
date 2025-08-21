import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/skill_stat.dart';
import '../services/training_stats_service.dart';

class SkillProgressCard extends StatelessWidget {
  const SkillProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context
        .watch<TrainingStatsService>()
        .skillStats
        .values
        .toList();
    if (stats.isEmpty) return const SizedBox.shrink();
    stats.sort((a, b) => b.evAvg.compareTo(a.evAvg));
    final top = stats.take(3).toList();
    stats.sort((a, b) => a.evAvg.compareTo(b.evAvg));
    final weak = stats.take(3).toList();
    Widget row(SkillStat s) {
      final v = ((s.evAvg + 5) / 10).clamp(0.0, 1.0);
      final color = v >= 0.5 ? Colors.green : Colors.red;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.category, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 2),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: v,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'EV ${s.evAvg.toStringAsFixed(2)} • ${s.mistakes}/${s.handsPlayed}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.assessment, color: Colors.lightBlueAccent),
              SizedBox(width: 8),
              Text(
                'Skill Progress',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final s in top) row(s),
          if (weak.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Weakest',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 4),
            for (final s in weak) row(s),
          ],
        ],
      ),
    );
  }
}
