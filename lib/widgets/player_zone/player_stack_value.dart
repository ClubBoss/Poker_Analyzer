import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Displays the current remaining stack with a chip icon.
class PlayerStackValue extends StatefulWidget {
  /// Amount of chips remaining for the player.
  final int stack;

  /// Scale factor controlling the size.
  final double scale;

  /// True when the player has pushed all chips and has no stack left.
  final bool isBust;

  const PlayerStackValue({
    Key? key,
    required this.stack,
    this.scale = 1.0,
    this.isBust = false,
  }) : super(key: key);

  @override
  State<PlayerStackValue> createState() => _PlayerStackValueState();
}

class _PlayerStackValueState extends State<PlayerStackValue>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  String _formatStack(int value) {
    if (value >= 1000) {
      final double thousands = value / 1000.0;
      return '${thousands.toStringAsFixed(thousands >= 10 ? 0 : 1)}K';
    }
    return value.toString();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant PlayerStackValue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stack != oldWidget.stack || widget.isBust != oldWidget.isBust) {
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
    if (widget.stack <= 0 && !widget.isBust) return const SizedBox.shrink();
    final iconSize = 12.0 * widget.scale;
    final textColor = widget.isBust ? Colors.grey : Colors.white;
    return AnimatedOpacity(
      opacity: widget.isBust ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: ScaleTransition(
        scale: _animation,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 6 * widget.scale,
            vertical: 2 * widget.scale,
          ),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8 * widget.scale),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.casino, size: iconSize, color: AppColors.accent),
              SizedBox(width: 4 * widget.scale),
              Text(
                _formatStack(widget.stack),
                style: TextStyle(
                  color: textColor,
                  fontSize: 12 * widget.scale,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
