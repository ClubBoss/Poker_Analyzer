import 'package:flutter/material.dart';

/// Small white label displaying total chips invested in the current hand.
class TotalInvestedLabel extends StatelessWidget {
  /// Total chips the player has invested so far.
  final int? total;

  /// Scale factor for sizing.
  final double scale;

  const TotalInvestedLabel({Key? key, required this.total, this.scale = 1.0})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (total == null || total! <= 0) return const SizedBox.shrink();
    return Text(
      '$total',
      style: TextStyle(
        color: Colors.white,
        fontSize: 12 * scale,
        fontWeight: FontWeight.w600,
        shadows: const [
          Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black54),
        ],
      ),
    );
  }
}
