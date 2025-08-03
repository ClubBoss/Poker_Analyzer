import 'package:flutter/material.dart';

/// Small fading label for a player's last action.
class ActionTagLabel extends StatelessWidget {
  final String text;
  final Color color;
  final double scale;

  const ActionTagLabel({
    Key? key,
    required this.text,
    required this.color,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 2 * scale),
      decoration: BoxDecoration(
        color: color.withOpacity(0.6),
        borderRadius: BorderRadius.circular(6 * scale),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 10 * scale,
        ),
      ),
    );
  }
}
