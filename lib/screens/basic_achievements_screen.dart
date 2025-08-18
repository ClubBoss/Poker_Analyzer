import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../services/achievements_engine.dart';
import '../models/achievement_basic.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final achievements = context.watch<AchievementsEngine>().achievements;
    return Scaffold(
      appBar: AppBar(title: const Text('Достижения'), centerTitle: true),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          final count = compact ? 1 : 2;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: achievements.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: count,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemBuilder: (context, index) {
              final a = achievements[index];
              return _AchievementCard(a);
            },
          );
        },
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final AchievementBasic achievement;
  const _AchievementCard(this.achievement);

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.isUnlocked;
    final date = achievement.unlockDate;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                unlocked ? Icons.check_circle : Icons.lock_outline,
                color: unlocked ? Colors.green : Colors.white54,
              ),
              const Spacer(),
              if (date != null)
                Text(
                  DateFormat(
                    'dd.MM.yyyy',
                    Intl.getCurrentLocale(),
                  ).format(date),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            achievement.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            achievement.description,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
