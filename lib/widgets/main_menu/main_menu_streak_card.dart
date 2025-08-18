import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/responsive.dart';
import '../../services/streak_service.dart';

class MainMenuStreakCard extends StatelessWidget {
  final bool showPopup;

  const MainMenuStreakCard({super.key, required this.showPopup});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<StreakService>();
    final streak = service.count;
    if (streak <= 0) return const SizedBox.shrink();

    const threshold = StreakService.bonusThreshold;
    final highlight = service.hasBonus;
    final progressDays = streak >= threshold ? threshold : streak;
    final progress = progressDays / threshold;
    final accent = Theme.of(context).colorScheme.secondary;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: EdgeInsets.only(bottom: responsiveSize(context, 24)),
          padding: responsiveAll(context, 12),
          decoration: BoxDecoration(
            color: highlight ? Colors.orange[700] : Colors.grey[850],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Стрик: $streak дней подряд',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 300),
                      builder: (context, value, _) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: value,
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              highlight ? Colors.white : accent,
                            ),
                            minHeight: 6,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$progressDays/$threshold',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showPopup)
          Positioned(
            top: -10,
            left: 0,
            right: 0,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Opacity(
                  opacity: 1 - value,
                  child: Transform.translate(
                    offset: Offset(0, -20 * value),
                    child: child,
                  ),
                );
              },
              child: const Text(
                '+1🔥',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
