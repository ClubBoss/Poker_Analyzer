import 'package:flutter/material.dart';
import 'chip_stack_moving_widget.dart';

/// Animated stack of chips flying from the pot to a player's stack.
class PotCollectionChips extends StatelessWidget {
  /// Global start position (center of the table).
  final Offset start;

  /// Global destination position at the winner's stack.
  final Offset end;

  /// Amount represented by the chips.
  final int amount;

  /// Scale factor applied to the animation.
  final double scale;

  /// Optional bezier control point for the curved path.
  final Offset? control;

  /// Callback when the animation completes.
  final VoidCallback? onCompleted;

  /// Fraction of the animation after which fading begins.
  final double fadeStart;

  const PotCollectionChips({
    Key? key,
    required this.start,
    required this.end,
    required this.amount,
    this.scale = 1.0,
    this.control,
    this.onCompleted,
    this.fadeStart = 0.7,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChipStackMovingWidget(
      start: start,
      end: end,
      amount: amount,
      color: Colors.orangeAccent,
      scale: scale,
      control: control,
      fadeStart: fadeStart,
      onCompleted: onCompleted,
    );
  }
}

/// Displays a [PotCollectionChips] above the current overlay.
void showPotCollectionChips({
  required BuildContext context,
  required Offset start,
  required Offset end,
  required int amount,
  double scale = 1.0,
  Offset? control,
  double fadeStart = 0.7,
}) {
  final overlay = Overlay.of(context);
  if (overlay == null) return;
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => PotCollectionChips(
      start: start,
      end: end,
      amount: amount,
      scale: scale,
      control: control,
      fadeStart: fadeStart,
      onCompleted: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}
