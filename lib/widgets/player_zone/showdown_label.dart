import 'package:flutter/material.dart';

class ShowdownLabel extends StatelessWidget {
  final String text;
  final double scale;
  final Animation<double> opacity;

  const ShowdownLabel({
    super.key,
    required this.text,
    required this.scale,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: opacity,
      child: Padding(
        padding: EdgeInsets.only(bottom: 4 * scale),
        child: Container(
          padding:
              EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 2 * scale),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8 * scale),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10 * scale,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
