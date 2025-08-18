import 'package:flutter/material.dart';

import '../services/daily_challenge_streak_service.dart';

/// Displays the current daily challenge streak.
class StreakBadgeWidget extends StatelessWidget {
  const StreakBadgeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: DailyChallengeStreakService.instance.getCurrentStreak(),
      builder: (context, snapshot) {
        final streak = snapshot.data;
        if (streak == null || streak <= 0) {
          return const SizedBox.shrink();
        }
        final label = streak == 1 ? '🔥 Новичок' : 'x$streak';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.deepOrange, Colors.orangeAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.deepOrange.withValues(alpha: 0.6),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.local_fire_department,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
