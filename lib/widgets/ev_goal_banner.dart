import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/saved_hand_manager_service.dart';

class EVGoalBanner extends StatelessWidget {
  const EVGoalBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final hands = context.watch<SavedHandManagerService>().hands;
    double recovered = 0;
    for (final h in hands) {
      if (h.corrected) recovered += h.evLossRecovered ?? 0;
    }
    const goals = [5, 10, 20, 50, 100];
    double next = goals.last.toDouble();
    for (final g in goals) {
      if (recovered < g) {
        next = g.toDouble();
        break;
      }
    }
    final progress = (recovered / next).clamp(0.0, 1.0);
    final accent = Theme.of(context).colorScheme.secondary;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Следующая цель EV',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '+${recovered.toStringAsFixed(1)} из ${next.toInt()} EV восстановлено',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
