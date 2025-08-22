import 'package:flutter/material.dart';

import '../services/training_pack_stats_service_v2.dart';

class BoosterProgressCard extends StatelessWidget {
  const BoosterProgressCard({super.key});

  Future<List<MapEntry<String, double>>> _load() async {
    final map = await TrainingPackStatsServiceV2.improvementByTag();
    final list = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MapEntry<String, double>>>(
      future: _load(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final list = snapshot.data!;
        final maxAbs = list
            .map((e) => e.value.abs())
            .reduce((a, b) => a > b ? a : b);
        Widget row(MapEntry<String, double> e) {
          final color = e.value >= 0 ? Colors.green : Colors.red;
          final icon = e.value >= 0 ? Icons.arrow_upward : Icons.arrow_downward;
          final progress = maxAbs > 0 ? e.value.abs() / maxAbs : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.key, style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 2),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(icon, color: color, size: 12),
                    Text(
                      '${(e.value * 100).abs().toStringAsFixed(1)}%',
                      style: TextStyle(color: color, fontSize: 12),
                    ),
                  ],
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
                  Icon(Icons.trending_up, color: Colors.amberAccent),
                  SizedBox(width: 8),
                  Text(
                    'Booster Progress',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final e in list) row(e),
            ],
          ),
        );
      },
    );
  }
}
