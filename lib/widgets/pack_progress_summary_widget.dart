import 'package:flutter/material.dart';

/// Displays progress towards pack unlock requirements.
class PackProgressSummaryWidget extends StatelessWidget {
  final double? accuracy; // 0..1
  final int? handsCompleted;
  final double? requiredAccuracy; // percent
  final int? minHands;

  const PackProgressSummaryWidget({
    super.key,
    this.accuracy,
    this.handsCompleted,
    this.requiredAccuracy,
    this.minHands,
  });

  Color _progressColor(double value, double target) {
    if (value >= target) return Colors.green;
    if (value >= target * 0.5) return Colors.yellow;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];
    final hasAccReq = requiredAccuracy != null && requiredAccuracy! > 0;
    final hasHandsReq = minHands != null && minHands! > 0;
    if (!hasAccReq && !hasHandsReq) return const SizedBox.shrink();
    if (hasAccReq) {
      final accPct = (accuracy ?? 0) * 100;
      final target = requiredAccuracy!;
      final color = _progressColor(accPct, target);
      widgets.add(LinearProgressIndicator(
        value: target == 0 ? 0 : accPct / target,
        backgroundColor: Colors.white24,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ));
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          'Точность: ${accPct.toStringAsFixed(0)}% / ≥${target.toStringAsFixed(0)}%',
          style: TextStyle(color: color, fontSize: 12),
        ),
      ));
    }
    if (hasHandsReq) {
      final hands = handsCompleted ?? 0;
      final target = minHands!.toDouble();
      final color = _progressColor(hands.toDouble(), target);
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 4),
        child: LinearProgressIndicator(
          value: target == 0 ? 0 : hands / target,
          backgroundColor: Colors.white24,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ));
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          'Руки: $hands / ≥${target.toStringAsFixed(0)}',
          style: TextStyle(color: color, fontSize: 12),
        ),
      ));
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets,
      ),
    );
  }
}
