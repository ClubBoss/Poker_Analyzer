import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/goal_engine.dart';

class GoalsCard extends StatelessWidget {
  const GoalsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<GoalEngine>();
    final accent = Theme.of(context).colorScheme.secondary;
    final goals = engine.goals;
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
            final g = goals[i];
            Text(g.title, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (g.currentXP / g.targetXP).clamp(0.0, 1.0),
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation(accent),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text('${g.currentXP}/${g.targetXP}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ),
            if (i != goals.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
