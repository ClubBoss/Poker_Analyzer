import 'package:flutter/material.dart';

class DealerButtonIndicator extends StatefulWidget {
  final double scale;
  const DealerButtonIndicator({super.key, this.scale = 1.0});

  @override
  State<DealerButtonIndicator> createState() => _DealerButtonIndicatorState();
}

class _DealerButtonIndicatorState extends State<DealerButtonIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
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
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2)],
        ),
        alignment: Alignment.center,
        child: Text(
          'D',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 12 * widget.scale,
          ),
        ),
      ),
    );
  }
}
