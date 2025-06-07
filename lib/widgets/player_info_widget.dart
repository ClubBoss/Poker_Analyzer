import 'package:flutter/material.dart';

/// Compact display for a player's position, stack and last action tag.
class PlayerInfoWidget extends StatelessWidget {
  final String position;
  final int stack;
  final String tag;
  final bool isActive;
  final bool isFolded;

  const PlayerInfoWidget({
    super.key,
    required this.position,
    required this.stack,
    required this.tag,
    this.isActive = false,
    this.isFolded = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget box = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
        border: isActive ? Border.all(color: Colors.orangeAccent, width: 2) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            position,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Stack: \$stack',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
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
        ],
      ),
    );

    if (isFolded) {
      box = Opacity(opacity: 0.5, child: box);
    }

    return box;
  }
}
