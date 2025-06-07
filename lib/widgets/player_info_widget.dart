import 'package:flutter/material.dart';

/// Compact display for a player's position, stack and last action tag.
class PlayerInfoWidget extends StatelessWidget {
  final String position;
  final int stack;
  final String tag;
  final bool isActive;
  final bool isFolded;
  final bool isHero;
  final String playerTypeIcon;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onStackTap;

  const PlayerInfoWidget({
    super.key,
    required this.position,
    required this.stack,
    required this.tag,
    this.isActive = false,
    this.isFolded = false,
    this.isHero = false,
    this.playerTypeIcon = '🔘',
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onStackTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isActive
        ? Colors.orangeAccent
        : isHero
            ? Colors.purpleAccent
            : null;

    Widget box = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
        border: borderColor != null
            ? Border.all(color: borderColor, width: 2)
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isHero) const Text('🦸', style: TextStyle(fontSize: 12)),
          Text(
            position,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: onStackTap,
            child: Text(
              'Stack: \$stack',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          if (tag.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                tag,
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(playerTypeIcon, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );

    if (isFolded) {
      box = Opacity(opacity: 0.5, child: box);
    }

    if (onLongPress != null) {
      box = Tooltip(message: 'Change player type', child: box);
    }

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      onLongPress: onLongPress,
      child: box,
    );
  }
}
