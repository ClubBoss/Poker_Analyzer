import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Displays a small pile of chips representing the player's remaining stack.
class PlayerStackChips extends StatelessWidget {
  /// Player stack in big blinds or chip units.
  final int stack;

  /// Scale factor depending on table size.
  final double scale;

  /// Whether the player has no remaining chips after an all-in.
  final bool isBust;

  const PlayerStackChips({
    Key? key,
    required this.stack,
    this.scale = 1.0,
    this.isBust = false,
  }) : super(key: key);

  Color _colorForStack() {
    if (stack >= 50) return Colors.redAccent;
    if (stack >= 10) return AppColors.accent;
    return Colors.blueAccent;
  }

  @override
  Widget build(BuildContext context) {
    if (stack <= 0 && !isBust) return const SizedBox.shrink();
    final chipCount = stack > 0 ? (stack / 10).clamp(1, 10).round() : 1;
    final double size = 10 * scale;
    final color = isBust ? Colors.grey : _colorForStack();

    return AnimatedOpacity(
      opacity: isBust ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: SizedBox(
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
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 3,
                        offset: const Offset(1, 2),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
