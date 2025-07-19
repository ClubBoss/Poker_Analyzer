import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/training_spot.dart';
import '../services/daily_challenge_service.dart';
import '../screens/daily_challenge_screen.dart';

class DailyChallengeCard extends StatelessWidget {
  const DailyChallengeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<DailyChallengeService>();
    final completed = service.isCompletedToday();
    return FutureBuilder<TrainingSpot?>(
      future: service.getTodayChallenge(),
      builder: (context, snapshot) {
        final spot = snapshot.data;
        if (spot == null) return const SizedBox.shrink();
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
              const Expanded(
                child: Text('Daily Challenge',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              if (completed)
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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
                    final spot = await service.getTodayChallenge();
                    if (spot == null) return;
                    // ignore: use_build_context_synchronously
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => DailyChallengeScreen(spot: spot)),
                    );
                  },
                  child: const Text('Start'),
                ),
            ],
          ),
        );
      },
    );
  }
}
