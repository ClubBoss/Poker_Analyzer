import 'package:flutter/material.dart';

/// Displays the current remaining stack with a chip icon.
class PlayerStackValue extends StatefulWidget {
  /// Amount of chips remaining for the player.
  final int stack;

  /// Scale factor controlling the size.
  final double scale;

  const PlayerStackValue({
    Key? key,
    required this.stack,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  State<PlayerStackValue> createState() => _PlayerStackValueState();
}

class _PlayerStackValueState extends State<PlayerStackValue>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

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
    if (widget.stack < oldWidget.stack) {
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
    if (widget.stack <= 0) return const SizedBox.shrink();
    final iconSize = 12.0 * widget.scale;
    return ScaleTransition(
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
            Icon(Icons.casino, size: iconSize, color: Colors.orangeAccent),
            SizedBox(width: 4 * widget.scale),
            Text(
              '${widget.stack}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12 * widget.scale,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
