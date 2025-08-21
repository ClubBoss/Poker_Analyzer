import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/weekly_drill_stats_service.dart';

class WeeklyDrillStatsCard extends StatelessWidget {
  const WeeklyDrillStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<WeeklyDrillStatsService>().stats;
    if (stats == null) return const SizedBox.shrink();
    final diff = stats.improvementPct;
    final color = diff > 0
        ? Colors.green
        : diff < 0
            ? Colors.red
            : Colors.grey;
    final icon = diff >= 0 ? Icons.trending_up : Icons.trending_down;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.insights, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekly Drill Stats',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stats.accuracy.toStringAsFixed(1)}% • ${stats.total} spots • streak ${stats.streak}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 2),
              Text(
                '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)}%',
                style: TextStyle(color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
