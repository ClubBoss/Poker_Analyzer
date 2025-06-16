import 'package:flutter/material.dart';
import '../services/pot_sync_service.dart';
import '../helpers/action_formatting_helper.dart';

/// Displays current pot size above the board cards.
class PotOverBoardWidget extends StatelessWidget {
  /// Provides synchronized pot information.
  final PotSyncService potSync;

  /// Current street index. 0 = preflop, 1 = flop, ...
  final int currentStreet;

  /// Scale factor to adapt to table size.
  final double scale;

  const PotOverBoardWidget({
    Key? key,
    required this.potSync,
    required this.currentStreet,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (currentStreet < 1) {
      return const SizedBox.shrink();
    }
    final potAmount = potSync.pots[currentStreet];
    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: const Alignment(0, -0.05),
          child: Transform.translate(
            offset: Offset(0, -15 * scale),
            child: Opacity(
              opacity: 0.7,
              child: Text(
                'Pot: ${ActionFormattingHelper.formatAmount(potAmount)}',
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
