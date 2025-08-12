import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/reward_system_service.dart';

class RewardBannerWidget extends StatelessWidget {
  const RewardBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RewardSystemService>(
      builder: (context, rewards, _) {
        final level = rewards.currentLevel;
        final xp = rewards.xpProgress;
        final target = rewards.xpToNextLevel;
        final progress = rewards.progress.clamp(0.0, 1.0);
        final accent = Theme.of(context).colorScheme.secondary;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('\uD83E\uDDE0 Уровень $level — $xp/$target XP',
                  style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
