import 'package:flutter/material.dart';

/// Displays the current pot amount with a label.
class PotDisplayWidget extends StatelessWidget {
  final String text;
  final double scale;

  const PotDisplayWidget({
    Key? key,
    required this.text,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: Container(
        key: ValueKey(text),
        padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 6 * scale),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(12 * scale),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16 * scale,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
