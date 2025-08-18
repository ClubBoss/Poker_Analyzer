import 'package:flutter/material.dart';

/// Progress bar for the number of sessions with accuracy greater than 80%.
class AccuracyProgressBar extends StatelessWidget {
  final int good;
  final int total;
  final double scale;

  const AccuracyProgressBar({
    super.key,
    required this.good,
    required this.total,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? good / total : 0.0;
    final accent = Theme.of(context).colorScheme.secondary;
    return Padding(
      padding: EdgeInsets.only(bottom: 12 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 360) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Сессии с точностью > 80%',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14 * scale,
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    Text(
                      '$good из $total',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14 * scale,
                      ),
                    ),
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Сессии с точностью > 80%',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14 * scale,
                    ),
                  ),
                  Text(
                    '$good из $total',
                    style: TextStyle(color: Colors.white, fontSize: 14 * scale),
                  ),
                ],
              );
            },
          ),
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
