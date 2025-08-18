import 'package:flutter/material.dart';

/// Displays progress towards unlocking a training pack.
class UnlockTrackerWidget extends StatelessWidget {
  final double? accuracy; // 0..1
  final int handsCompleted;
  final double? requiredAccuracy; // percent
  final int? minHands;

  const UnlockTrackerWidget({
    super.key,
    this.accuracy,
    required this.handsCompleted,
    this.requiredAccuracy,
    this.minHands,
  });

  Color _progressColor(double ratio) {
    if (ratio >= 1) return Colors.green;
    if (ratio >= 0.5) return Colors.yellow;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final hasAccReq = requiredAccuracy != null && requiredAccuracy! > 0;
    final hasHandsReq = minHands != null && minHands! > 0;
    if (!hasAccReq && !hasHandsReq) return const SizedBox.shrink();

    final accPct = (accuracy ?? 0) * 100;
    final accRatio = hasAccReq && requiredAccuracy! > 0
        ? accPct / requiredAccuracy!
        : 1;
    final handsRatio = hasHandsReq && minHands! > 0
        ? handsCompleted / minHands!.toDouble()
        : 1;
    final progress = [accRatio, handsRatio].reduce((a, b) => a < b ? a : b);
    final color = _progressColor(progress);

    final widgets = <Widget>[
      LinearProgressIndicator(
        value: progress.clamp(0, 1),
        backgroundColor: Colors.white24,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    ];

    if (hasAccReq) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            'Точность: ${accPct.toStringAsFixed(0)}% / ≥${requiredAccuracy!.toStringAsFixed(0)}%',
            style: TextStyle(color: color, fontSize: 12),
          ),
        ),
      );
    }

    if (hasHandsReq) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            'Руки: $handsCompleted / ≥${minHands!.toString()}',
            style: TextStyle(color: color, fontSize: 12),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
