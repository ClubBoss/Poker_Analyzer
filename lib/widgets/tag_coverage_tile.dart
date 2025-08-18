import 'package:flutter/material.dart';

import '../screens/tag_insight_screen.dart';

class TagCoverageTile extends StatelessWidget {
  final String tag;
  final int count;
  final int max;
  final VoidCallback? onTap;

  const TagCoverageTile({
    super.key,
    required this.tag,
    required this.count,
    required this.max,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = max > 0 ? count / max : 0.0;
    final color = Color.lerp(
      const Color(0xFF444444),
      const Color(0xFFFFA500),
      t,
    )!;
    return GestureDetector(
      onTap:
          onTap ??
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TagInsightScreen(tag: tag)),
          ),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(8),
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
            Text('$count', style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
