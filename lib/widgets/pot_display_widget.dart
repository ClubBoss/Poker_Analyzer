import 'package:flutter/material.dart';

/// Simple widget that displays the current pot amount.
///
/// Shows a rounded semi-transparent background with a white label
/// "Pot: X" where `X` is the amount. When the amount changes the
/// label fades between the values and briefly scales up when the
/// amount increases.
class PotDisplayWidget extends StatefulWidget {
  /// Amount of chips currently in the pot.
  final int amount;

  /// Scale factor for the text and padding.
  final double scale;

  const PotDisplayWidget({Key? key, required this.amount, this.scale = 1.0})
    : super(key: key);

  @override
  State<PotDisplayWidget> createState() => _PotDisplayWidgetState();
}

class _PotDisplayWidgetState extends State<PotDisplayWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim =
        Tween<double>(begin: 1.0, end: 1.1).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOut),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _controller.reverse();
          }
        });
  }

  @override
  void didUpdateWidget(covariant PotDisplayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.amount > oldWidget.amount) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: widget.amount > 0
            ? Container(
                key: ValueKey(widget.amount),
                padding: EdgeInsets.symmetric(
                  horizontal: 12 * widget.scale,
                  vertical: 6 * widget.scale,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12 * widget.scale),
                ),
                child: Text(
                  'Pot: ${widget.amount}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16 * widget.scale,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
