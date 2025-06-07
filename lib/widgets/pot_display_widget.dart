import 'package:flutter/material.dart';

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

  String _formatAmount(int amount) {
    final digits = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 1, end: 1.1).animate(
        CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: widget.amount.toDouble()),
        duration: const Duration(milliseconds: 300),
        builder: (context, value, child) {
          final text = 'Pot ${_formatAmount(value.round())}';
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            ),
            child: Container(
              key: ValueKey(text),
              padding: EdgeInsets.symmetric(
                horizontal: 12 * widget.scale,
                vertical: 6 * widget.scale,
              ),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(12 * widget.scale),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16 * widget.scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
