import 'package:flutter/material.dart';

/// Displays accuracy information for a specific player position.
class PositionAccuracyRow extends StatelessWidget {
  final String position;
  final int correct;
  final int total;
  final double scale;
  final VoidCallback? onTap;

  const PositionAccuracyRow({
    super.key,
    required this.position,
    required this.correct,
    required this.total,
    required this.scale,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accuracy = total > 0 ? (correct / total * 100).round() : 0;
    final row = Padding(
      padding: EdgeInsets.only(bottom: 12 * scale),
      child: Text(
        '$position - $accuracy% точность ($correct из $total верно)',
        style: TextStyle(color: Colors.white, fontSize: 14 * scale),
      ),
    );
    return onTap != null ? InkWell(onTap: onTap, child: row) : row;
  }
}
