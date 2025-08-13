import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/xp_tracker_service.dart';
import '../models/level_stage.dart';

class XPProgressCard extends StatelessWidget {
  const XPProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<XPTrackerService>();
    final level = service.level;
    final xp = service.xp;
    final next = service.nextLevelXp;
    final progress = service.progress.clamp(0.0, 1.0);
    final stage = stageForLevel(level);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.star, color: stage.color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${stage.label} Level $level',
                  style: TextStyle(
                      color: stage.color, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('$xp / $next XP',
                    style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation(stage.color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
