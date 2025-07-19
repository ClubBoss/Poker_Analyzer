import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/training_spot.dart';
import '../services/daily_challenge_service.dart';
import '../services/daily_challenge_meta_service.dart';
import '../screens/daily_challenge_screen.dart';
import '../screens/daily_challenge_result_screen.dart';

class DailyChallengeCard extends StatelessWidget {
  const DailyChallengeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<DailyChallengeService>();
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        service.getTodayChallenge(),
        DailyChallengeMetaService.instance.getTodayState(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final spot = snapshot.data![0] as TrainingSpot?;
        final state = snapshot.data![1] as ChallengeState;
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
                child: Text(
                  'Daily Challenge',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              if (state == ChallengeState.locked)
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Locked 🔒',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              else
                ElevatedButton(
                  onPressed: () async {
                    if (state == ChallengeState.locked) return;
                    if (state == ChallengeState.completed) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              DailyChallengeResultScreen(spot: spot),
                        ),
                      );
                      return;
                    }
                    final spot = await service.getTodayChallenge();
                    if (spot == null) return;
                    // ignore: use_build_context_synchronously
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DailyChallengeScreen(spot: spot),
                      ),
                    );
                  },
                  child: Text(
                    state == ChallengeState.completed ? 'Result' : 'Start',
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
