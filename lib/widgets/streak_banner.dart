import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/goals_service.dart';
import '../screens/error_free_streak_screen.dart';

/// Displays the current "Без ошибок подряд" streak as a small banner.
/// Fades in and out when the value changes.
class StreakBanner extends StatelessWidget {
  const StreakBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final streak = context.watch<GoalsService>().errorFreeStreak;
    final accent = Theme.of(context).colorScheme.secondary;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: streak >= 1
          ? GestureDetector(
              key: ValueKey<int>(streak),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ErrorFreeStreakScreen(),
                  ),
                );
              },
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.flash_on, color: accent, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '$streak',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Держите темп!',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox.shrink(key: ValueKey('empty')),
    );
  }
}
