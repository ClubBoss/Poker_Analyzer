import 'package:flutter/material.dart';

/// Generic progress bar widget for XP indicators.
class XPProgressBarWidget extends StatelessWidget {
  /// Current accumulated XP.
  final int currentXp;

  /// XP required for the next level.
  final int nextLevelXp;

  /// Progress value between 0 and 1.
  final double progress;

  /// Optional title displayed above the bar.
  final String? label;

  /// Optional color of the progress indicator.
  final Color? color;

  const XPProgressBarWidget({
    super.key,
    required this.currentXp,
    required this.nextLevelXp,
    required this.progress,
    this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? Theme.of(context).colorScheme.secondary;
    final pct = progress.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
        ],
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$currentXp / $nextLevelXp XP',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ],
    );
  }
}
