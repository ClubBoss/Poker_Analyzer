import 'package:flutter/material.dart';

/// Displays a small pile of chips representing the player's remaining stack.
class PlayerStackChips extends StatelessWidget {
  /// Player stack in big blinds or chip units.
  final int stack;

  /// Scale factor depending on table size.
  final double scale;

  const PlayerStackChips({
    Key? key,
    required this.stack,
    this.scale = 1.0,
  }) : super(key: key);

  Color _colorForStack() {
    if (stack >= 50) return Colors.redAccent;
    if (stack >= 10) return Colors.orangeAccent;
    return Colors.blueAccent;
  }

  @override
  Widget build(BuildContext context) {
    if (stack <= 0) return const SizedBox.shrink();
    final chipCount = (stack / 10).clamp(1, 10).round();
    final double size = 10 * scale;
    final color = _colorForStack();

    return SizedBox(
      width: size * 2,
      height: size + chipCount * size * 0.35,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          for (int i = 0; i < chipCount; i++)
            Positioned(
              bottom: i * size * 0.35,
              child: Container(
                width: size * 2,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [color, Colors.black],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((255 * 0.6).round()),
                      blurRadius: 3,
                      offset: const Offset(1, 2),
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
