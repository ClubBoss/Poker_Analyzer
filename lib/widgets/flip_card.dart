import 'dart:math';
import 'package:flutter/material.dart';

class FlipCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  final bool showFront;
  final Duration duration;
  final double width;
  final double height;

  const FlipCard({
    Key? key,
    required this.front,
    required this.back,
    required this.showFront,
    this.duration = const Duration(milliseconds: 500),
    this.width = 36,
    this.height = 52,
  }) : super(key: key);

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: widget.showFront ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(covariant FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showFront != widget.showFront) {
      if (widget.showFront) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final value = _controller.value;
          double angle = value * pi;
          Widget childWidget;
          if (value <= 0.5) {
            childWidget = widget.back;
          } else {
            angle = angle - pi;
            childWidget = widget.front;
          }
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: childWidget,
          );
        },
      ),
    );
  }
}
