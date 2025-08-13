import 'package:flutter/material.dart';

class TagInsightHeader extends StatelessWidget {
  final String tag;
  final double skillLevel; // 0.0 - 1.0
  final String trend;
  final int handsAnalyzed;

  const TagInsightHeader({
    super.key,
    required this.tag,
    required this.skillLevel,
    required this.trend,
    required this.handsAnalyzed,
  });

  Color _barColor() {
    return Color.lerp(Colors.red, Colors.green, skillLevel.clamp(0.0, 1.0)) ??
        Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final color = _barColor();
    final up = !trend.trim().startsWith('-');
    final trendIcon = up ? Icons.trending_up : Icons.trending_down;
    final trendColor = up ? Colors.green : Colors.red;
    final name = tag.isNotEmpty ? tag[0].toUpperCase() + tag.substring(1) : tag;
    return Container(
      padding: const EdgeInsets.all(12),
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: skillLevel.clamp(0.0, 1.0),
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(trendIcon, size: 14, color: trendColor),
              const SizedBox(width: 4),
              Text(
                trend,
                style: TextStyle(color: trendColor, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Based on $handsAnalyzed hands',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
