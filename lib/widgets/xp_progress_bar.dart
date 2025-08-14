import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/xp_tracker_service.dart';
import '../screens/achievements_screen.dart';

class XPProgressBar extends StatelessWidget {
  const XPProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<XPTrackerService>();
    final level = service.level;
    final xp = service.xp;
    final next = service.nextLevelXp;
    final progress = service.progress.clamp(0.0, 1.0);
    final accent = Theme.of(context).colorScheme.secondary;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AchievementsScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Level $level - $xp / $next XP',
                style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 4),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, _) => ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                  minHeight: 6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
