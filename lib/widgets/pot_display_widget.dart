import 'package:flutter/material.dart';
import 'chip_widget.dart';

/// Displays the current pot amount with a label and animates changes.
class PotDisplayWidget extends StatefulWidget {
  /// Current pot amount.
  final int amount;

  /// Scale factor to adapt to table size.
  final double scale;

  const PotDisplayWidget({
    Key? key,
    required this.amount,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  State<PotDisplayWidget> createState() => _PotDisplayWidgetState();
}

class _PotDisplayWidgetState extends State<PotDisplayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _scaleController.reverse();
        }
      });
  }

  @override
  void didUpdateWidget(covariant PotDisplayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.amount > oldWidget.amount) {
      _scaleController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.amount <= 0) return const SizedBox.shrink();

    return ScaleTransition(
      scale: Tween<double>(begin: 1, end: 1.1).animate(
        CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        ),
        child: Column(
          key: ValueKey(widget.amount),
          mainAxisSize: MainAxisSize.min,
          children: [
            ChipWidget(amount: widget.amount, scale: widget.scale * 1.3),
            SizedBox(height: 4 * widget.scale),
            Text(
              'Pot',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14 * widget.scale,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
