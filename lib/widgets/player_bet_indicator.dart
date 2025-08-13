import 'package:flutter/material.dart';
import 'chip_trail.dart';

/// Small chip icon with amount text representing a bet, raise or call.
class PlayerBetIndicator extends StatelessWidget {
  final String action;
  final int amount;
  final double scale;

  const PlayerBetIndicator({
    Key? key,
    required this.action,
    required this.amount,
    this.scale = 1.0,
  }) : super(key: key);

  Color _color() {
    switch (action) {
      case 'raise':
        return Colors.green;
      case 'call':
        return Colors.blue;
      case 'bet':
      default:
        return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (amount <= 0) return const SizedBox.shrink();
    final color = _color();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: Container(
        key: ValueKey('$action-$amount'),
        padding:
            EdgeInsets.symmetric(horizontal: 4 * scale, vertical: 2 * scale),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(8 * scale),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MiniChip(color: color, size: 12 * scale),
            SizedBox(width: 4 * scale),
            Text(
              '$amount',
              style: TextStyle(color: Colors.white, fontSize: 12 * scale),
            ),
          ],
        ),
      ),
    );
  }
}
