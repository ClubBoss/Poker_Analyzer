import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/xp_tracker_service.dart';

/// Displays the current level and progress toward the next level.
class LevelBadgeWidget extends StatelessWidget {
  const LevelBadgeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final xp = context.watch<XPTrackerService>();
    final level = xp.level;
    final progress = xp.progress.clamp(0.0, 1.0);
    final currentXp = xp.xp;
    final nextXp = xp.nextLevelXp;
    final accent = Theme.of(context).colorScheme.secondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent,
            ),
            alignment: Alignment.center,
            child: Text(
              '$level',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Уровень $level',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                Text(
                  '$currentXp / $nextXp XP',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
