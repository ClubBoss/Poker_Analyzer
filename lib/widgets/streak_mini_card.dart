import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/streak_counter_service.dart';

class StreakMiniCard extends StatelessWidget {
  const StreakMiniCard({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<StreakCounterService>();
    final accent = Theme.of(context).colorScheme.secondary;
    const messages = ['Keep it up!', 'Great focus!', 'Stay sharp!'];
    final quote = messages[service.count % messages.length];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text('🔥', style: TextStyle(fontSize: 20, color: accent)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Streak: ${service.count}',
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  'Best: ${service.max}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(quote, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
