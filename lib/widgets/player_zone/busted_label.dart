import 'package:flutter/material.dart';

class BustedLabel extends StatelessWidget {
  final double scale;
  final Animation<double> opacity;
  final Animation<Offset> offset;

  const BustedLabel({
    super.key,
    required this.scale,
    required this.opacity,
    required this.offset,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: -24 * scale,
      child: SlideTransition(
        position: offset,
        child: FadeTransition(
          opacity: opacity,
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: 6 * scale, vertical: 2 * scale),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8 * scale),
            ),
            child: Text(
              'BUSTED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10 * scale,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
