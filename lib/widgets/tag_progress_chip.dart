import 'package:flutter/material.dart';

import '../screens/tag_insight_screen.dart';

/// Chip displaying tag progress as a colored pill.
class TagProgressChip extends StatelessWidget {
  final String tag;
  final double progress; // 0.0 - 1.0
  final VoidCallback? onTap;

  const TagProgressChip({
    super.key,
    required this.tag,
    required this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final value = progress.clamp(0.0, 1.0);
    final color = Color.lerp(Colors.red, Colors.green, value) ?? Colors.red;
    final pct = (value * 100).round();
    return GestureDetector(
      onTap:
          onTap ??
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TagInsightScreen(tag: tag)),
          ),
      child: Chip(
        label: Text(
          '$tag $pct%',
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
        backgroundColor: color,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
      ),
    );
  }
}
