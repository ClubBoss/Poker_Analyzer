import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/daily_target_service.dart';
import '../screens/saved_hands_screen.dart';

class DailyProgressRing extends StatelessWidget {
  const DailyProgressRing({super.key});

  Color _color(double value) {
    if (value <= 0.5) {
      return Color.lerp(Colors.red, Colors.yellow, value * 2)!;
    }
    return Color.lerp(Colors.yellow, Colors.green, (value - 0.5) * 2)!;
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<DailyTargetService>();
    final target = service.target;
    final hands = service.progress;
    final progress = target > 0 ? hands / target : 0.0;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const SavedHandsScreen(initialDateFilter: 'Сегодня'),
          ),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Hands Today', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, _) {
                final percent = (value * 100).clamp(0, 100).round();
                return SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: value,
                        strokeWidth: 8,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation(_color(value)),
                      ),
                      Text(
                        '$percent%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              '$hands/$target',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
