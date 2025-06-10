import 'package:flutter/material.dart';
import 'chip_widget.dart';
import 'chip_trail.dart';

/// Widget that displays the pot amount in the center of the table.
///
/// The value smoothly animates when it increases. The amount is shown
/// on top of a semi-transparent circle with a fade and scale animation.
/// When the pot grows additional chip icons appear below the number.
class PotAnimationWidget extends StatefulWidget {
  /// Current pot amount.
  final int potAmount;

  /// Scale factor for sizing.
  final double scale;

  const PotAnimationWidget({
    Key? key,
    required this.potAmount,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  State<PotAnimationWidget> createState() => _PotAnimationWidgetState();
}

class _PotAnimationWidgetState extends State<PotAnimationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void didUpdateWidget(covariant PotAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.potAmount > oldWidget.potAmount) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildChips() {
    final double scale = widget.scale;
    if (widget.potAmount > 100) {
      return ChipWidget(amount: widget.potAmount, scale: 0.7 * scale);
    }
    final int count = (widget.potAmount / 20).clamp(1, 5).round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        count,
        (index) => Padding(
          padding: EdgeInsets.symmetric(horizontal: 1 * scale),
          child: MiniChip(color: Colors.orangeAccent, size: 10 * scale),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double size = 32 * widget.scale;
    return SizedBox(
      width: size * 2,
      height: size * 2,
      child: FadeTransition(
        opacity: _controller.drive(CurveTween(curve: Curves.easeIn)),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size * 2,
                height: size * 2,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  widget.potAmount.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18 * widget.scale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Positioned(
                bottom: 4 * widget.scale,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _controller.isAnimating || _controller.completed
                      ? 1.0
                      : 0.0,
                  child: _buildChips(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
