import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/streak_service.dart';
import '../services/reward_service.dart';

class WeeklyChestCard extends StatelessWidget {
  const WeeklyChestCard({super.key});

  @override
  Widget build(BuildContext context) {
    final streak = context.watch<StreakService>();
    final days = streak.weeklyActiveDays;
    final progress = (days / 5).clamp(0.0, 1.0);
    final accent = Theme.of(context).colorScheme.secondary;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard, color: Colors.orangeAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Weekly Chest',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation(accent),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text('$days / 5 days',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (streak.weeklyChestClaimed)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Received ✅',
                  style: TextStyle(color: Colors.white)),
            )
          else if (streak.weeklyChestAvailable)
            ElevatedButton(
              onPressed: () async {
                final reward = await context
                    .read<StreakService>()
                    .claimWeeklyChest(context.read<RewardService>());
                if (!context.mounted || reward == null) return;
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Congratulations!'),
                    content: Text('You got $reward'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Open'),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}
