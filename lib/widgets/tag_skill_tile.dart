import 'package:flutter/material.dart';
import 'package:poker_analyzer/ui/padding_constants.dart';

import '../screens/tag_insight_screen.dart';

class TagSkillTile extends StatelessWidget {
  final String tag;
  final double value;
  final VoidCallback? onTap;

  const TagSkillTile({
    super.key,
    required this.tag,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color.lerp(Colors.red, Colors.green, value) ?? Colors.red;
    return GestureDetector(
      onTap:
          onTap ??
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TagInsightScreen(tag: tag)),
          ),
      child: Container(
        padding: kCardPadding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              tag,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(value * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
