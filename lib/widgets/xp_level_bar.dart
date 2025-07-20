import 'package:flutter/material.dart';

class XPLevelBar extends StatelessWidget {
  final int currentXp;
  final int levelXp;
  final int level;

  const XPLevelBar({
    super.key,
    required this.currentXp,
    required this.levelXp,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    final pct = levelXp > 0 ? (currentXp / levelXp).clamp(0.0, 1.0) : 0.0;
    final barColor = currentXp >= levelXp ? Colors.greenAccent : accent;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Level $level',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('$currentXp / $levelXp XP',
                  style: const TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 4),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: pct),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation(barColor),
                  minHeight: 6,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
