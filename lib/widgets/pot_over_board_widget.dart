import 'package:flutter/material.dart';
import '../models/action_entry.dart';

/// Displays current pot size above the board cards.
class PotOverBoardWidget extends StatelessWidget {
  /// Visible actions up to the current playback index.
  final List<ActionEntry> visibleActions;

  /// Current street index. 0 = preflop, 1 = flop, ...
  final int currentStreet;

  /// Scale factor to adapt to table size.
  final double scale;

  const PotOverBoardWidget({
    Key? key,
    required this.visibleActions,
    required this.currentStreet,
    this.scale = 1.0,
  }) : super(key: key);

  double _calculatePot() {
    return visibleActions
        .where((a) =>
            a.street <= currentStreet &&
            (a.action == 'call' || a.action == 'bet' || a.action == 'raise'))
        .fold<double>(0, (sum, a) => sum + (a.amount ?? 0).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    if (currentStreet < 1) {
      return const SizedBox.shrink();
    }
    final potAmount = _calculatePot();
    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: const Alignment(0, -0.05),
          child: Transform.translate(
            offset: Offset(0, -15 * scale),
            child: Opacity(
              opacity: 0.7,
              child: Text(
                'Pot: ${potAmount.toStringAsFixed(1)} BB',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14 * scale,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
