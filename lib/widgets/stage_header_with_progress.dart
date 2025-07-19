import 'package:flutter/material.dart';

class StageHeaderWithProgress extends StatelessWidget {
  final String title;
  final int levelIndex;
  final String goal;
  final double progress;
  final bool showProgress;
  const StageHeaderWithProgress({
    super.key,
    required this.title,
    required this.levelIndex,
    required this.goal,
    required this.progress,
    this.showProgress = true,
  });

  Color _color(BuildContext context) {
    if (progress >= 1.0) return Colors.green;
    if (progress > 0.0) return Colors.yellow;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width - 32;
    final pct = (progress * 100).round();
    final barColor = _color(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Уровень $levelIndex: $title',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) =>
                Opacity(opacity: value, child: child),
            child: Text(
              goal,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          if (showProgress) ...[
            const SizedBox(height: 4),
            Text(
              'Прогресс: $pct%',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 4),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, _) => SizedBox(
                width: width,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 6.0,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
