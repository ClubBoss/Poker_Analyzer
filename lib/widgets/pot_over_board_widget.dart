import 'package:flutter/material.dart';
import '../services/pot_sync_service.dart';
import '../widgets/bet_stack_chips.dart';

/// Displays current pot size above the board cards.
class PotOverBoardWidget extends StatelessWidget {
  /// Provides synchronized pot information.
  final PotSyncService potSync;

  /// Current street index. 0 = preflop, 1 = flop, ...
  final int currentStreet;

  /// Scale factor to adapt to table size.
  final double scale;

  /// Whether the pot should be displayed.
  final bool show;

  const PotOverBoardWidget({
    Key? key,
    required this.potSync,
    required this.currentStreet,
    this.scale = 1.0,
    this.show = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!show || currentStreet < 1) {
      return const SizedBox.shrink();
    }
    final potAmount = potSync.pots[currentStreet];
    if (potAmount <= 0) {
      return const SizedBox.shrink();
    }
    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: const Alignment(0, -0.05),
          child: Transform.translate(
            offset: Offset(0, -15 * scale),
            child: BetStackChips(
              amount: potAmount,
              scale: scale,
            ),
          ),
        ),
      ),
    );
  }
}
