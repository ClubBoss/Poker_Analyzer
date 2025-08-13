import 'package:flutter/material.dart';

class BlindChipIndicator extends StatefulWidget {
  final String label;
  final Color color;
  final double scale;
  const BlindChipIndicator(
      {super.key, required this.label, required this.color, this.scale = 1.0});

  @override
  State<BlindChipIndicator> createState() => _BlindChipIndicatorState();
}

class _BlindChipIndicatorState extends State<BlindChipIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300))
      ..forward();
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
      child: Container(
        width: 20 * widget.scale,
        height: 20 * widget.scale,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
        ),
        alignment: Alignment.center,
        child: Text(
          widget.label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 10 * widget.scale,
          ),
        ),
      ),
    );
  }
}
