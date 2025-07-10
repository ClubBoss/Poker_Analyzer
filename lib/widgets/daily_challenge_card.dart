import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/daily_challenge_service.dart';
import '../services/training_session_service.dart';
import '../screens/training_session_screen.dart';

class DailyChallengeCard extends StatelessWidget {
  const DailyChallengeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<DailyChallengeService>();
    final tpl = service.template;
    if (tpl == null) return const SizedBox.shrink();
    final completed = service.rewarded;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.flash_on, color: Colors.amberAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Daily Challenge',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(tpl.name,
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (completed)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Completed ✅',
                  style: TextStyle(color: Colors.white)),
            )
          else
            ElevatedButton(
              onPressed: () async {
                await context
                    .read<TrainingSessionService>()
                    .startSession(tpl);
                if (context.mounted) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const TrainingSessionScreen()),
                  );
                }
              },
              child: const Text('Start'),
            ),
        ],
      ),
    );
  }
}
