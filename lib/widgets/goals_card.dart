import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/goals_tracker_service.dart';
import 'reward_dialog.dart';

class GoalsCard extends StatelessWidget {
  const GoalsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<GoalsTrackerService>();
    final accent = Theme.of(context).colorScheme.secondary;
    final goals = service.activeGoals;
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
          const Text('Goals',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (var i = 0; i < goals.length; i++) ...[
            Text(goals[i].title,
                style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (goals[i].progress / goals[i].target).clamp(0.0, 1.0),
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation(accent),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('${goals[i].progress}/${goals[i].target}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const Spacer(),
                if (goals[i].progress >= goals[i].target && !goals[i].completed)
                  ElevatedButton(
                    onPressed: () async {
                      await service.claim(goals[i].type);
                      if (context.mounted) {
                        showDialog(
                          context: context,
                          builder: (_) => RewardDialog(reward: goals[i].reward),
                        );
                      }
                    },
                    child: const Text('Claim'),
                  )
                else if (goals[i].completed)
                  const Text('Completed',
                      style: TextStyle(color: Colors.greenAccent)),
              ],
            ),
            if (i != goals.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
