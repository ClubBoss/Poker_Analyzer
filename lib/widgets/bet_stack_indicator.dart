import 'dart:async';
import 'package:flutter/material.dart';
import 'chip_stack_widget.dart';

/// Temporary chip stack display used when a player bets.
class BetStackIndicator extends StatefulWidget {
  final int amount;
  final Color color;
  final double scale;
  final Duration duration;
  final VoidCallback onComplete;

  const BetStackIndicator({
    Key? key,
    required this.amount,
    required this.color,
    required this.onComplete,
    this.scale = 1.0,
    this.duration = const Duration(milliseconds: 800),
  }) : super(key: key);

  @override
  State<BetStackIndicator> createState() => _BetStackIndicatorState();
}

class _BetStackIndicatorState extends State<BetStackIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _controller.forward();
    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse();
      }
    });
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ChipStackWidget(
            amount: widget.amount,
            scale: widget.scale,
            color: widget.color,
          ),
          SizedBox(height: 2 * widget.scale),
          Text(
            '+${widget.amount}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10 * widget.scale,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
