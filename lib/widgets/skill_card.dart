import 'package:flutter/material.dart';
import 'package:poker_analyzer/ui/padding_constants.dart';

import 'tag_progress_sparkline.dart';

class SkillCard extends StatelessWidget {
  final String tag;
  final double mastery;
  final int totalXp;
  final VoidCallback? onTap;

  const SkillCard({
    super.key,
    required this.tag,
    required this.mastery,
    required this.totalXp,
    this.onTap,
  });

  String _capitalize(String s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : s;

  @override
  Widget build(BuildContext context) {
    final color = Color.lerp(Colors.red, Colors.green, mastery.clamp(0.0, 1.0)) ?? Colors.red;
    final name = _capitalize(tag);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: kCardPadding,
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Mastery: ${(mastery * 100).round()}% \u00b7 XP: $totalXp',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TagProgressSparkline(tag: tag),
          ],
        ),
      ),
    );
  }
}
