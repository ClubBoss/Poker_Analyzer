import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/weekly_challenge_service.dart';
import '../screens/training_pack_review_screen.dart';

class WeeklyChallengeCard extends StatelessWidget {
  const WeeklyChallengeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<WeeklyChallengeService>();
    final challenge = service.current;
    final progressValue = service.progressValue;
    final target = challenge.target;
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
          const Icon(Icons.flag, color: Colors.greenAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: service.progress,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '$progressValue/$target',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${service.daysLeft} days left',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (progressValue >= target)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Completed ✅',
                style: TextStyle(color: Colors.white),
              ),
            )
          else
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TrainingPackReviewScreen(pack: service.currentPack),
                  ),
                );
              },
              child: const Text('Start'),
            ),
        ],
      ),
    );
  }
}
