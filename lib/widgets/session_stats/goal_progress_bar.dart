import 'package:flutter/material.dart';

/// Progress bar for the monthly goal of ten sessions with accuracy over 90%.
class GoalProgressBar extends StatelessWidget {
  final int good;
  final double scale;

  const GoalProgressBar({
    super.key,
    required this.good,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (good / 10.0).clamp(0.0, 1.0);
    final accent = Theme.of(context).colorScheme.secondary;
    return Padding(
      padding: EdgeInsets.only(bottom: 12 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth < 360) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Цель месяца: 10 сессий с точностью > 90%',
                      style: TextStyle(color: Colors.white70, fontSize: 14 * scale)),
                  SizedBox(height: 4 * scale),
                  Text('$good из 10',
                      style: TextStyle(color: Colors.white, fontSize: 14 * scale)),
                ],
              );
            }
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text('Цель месяца: 10 сессий с точностью > 90%',
                      style: TextStyle(color: Colors.white70, fontSize: 14 * scale)),
                ),
                Text('$good из 10',
                    style: TextStyle(color: Colors.white, fontSize: 14 * scale)),
              ],
            );
          }),
          SizedBox(height: 4 * scale),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
              minHeight: 6 * scale,
            ),
          ),
        ],
      ),
    );
  }
}
