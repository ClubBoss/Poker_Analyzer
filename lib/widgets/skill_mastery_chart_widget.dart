import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/training_session_service.dart';

class SkillMasteryChartWidget extends StatelessWidget {
  const SkillMasteryChartWidget({super.key});

  Color _color(double value) {
    if (value >= 0.9) return Colors.green;
    if (value >= 0.7) return Colors.yellow.shade700;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<TrainingSessionService>().getCategoryStats();
    final entries = <MapEntry<String, double>>[];
    stats.forEach((key, value) {
      if (value.played > 0) {
        entries.add(MapEntry(key, value.correct / value.played));
      }
    });
    if (entries.isEmpty) return const SizedBox.shrink();
    entries.sort((a, b) => a.value.compareTo(b.value));
    final data = entries.take(6).toList();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Skill Breakdown',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          for (final e in data)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      e.key,
                      style: const TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: e.value,
                        minHeight: 8,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _color(e.value),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(e.value * 100).round()}%',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
