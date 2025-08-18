import 'package:flutter/material.dart';

import '../services/theory_streak_service.dart';

/// Small badge showing current theory streak with best streak in a tooltip.
class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: TheoryStreakService.instance.getCurrentStreak(),
      builder: (context, snapshot) {
        final current = snapshot.data ?? 0;
        if (current <= 0) return const SizedBox.shrink();
        return FutureBuilder<int>(
          future: TheoryStreakService.instance.getMaxStreak(),
          builder: (context, maxSnap) {
            final best = maxSnap.data ?? current;
            final badge = Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.deepOrangeAccent.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$current д',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
            return Tooltip(message: 'Лучший стрик: $best', child: badge);
          },
        );
      },
    );
  }
}
