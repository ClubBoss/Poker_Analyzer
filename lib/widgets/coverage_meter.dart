import 'package:flutter/material.dart';

class CoverageMeter extends StatelessWidget {
  final double percent;
  const CoverageMeter(this.percent, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (percent / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Coverage: ${percent.round()}%',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
