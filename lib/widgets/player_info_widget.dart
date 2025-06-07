import 'package:flutter/material.dart';

/// Compact display for a player's position, stack, tag and last action.
class PlayerInfoWidget extends StatelessWidget {
  final String position;
  final int stack;
  final String tag;
  /// Last action taken by the player ('fold', 'call', 'bet', 'raise', 'check').
  final String? lastAction;
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
    this.lastAction,
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

    Color? actionColor;
    String? actionIcon;
    String? actionLabel;
    switch (lastAction) {
      case 'fold':
        actionColor = Colors.red;
        actionIcon = '❌';
        actionLabel = 'Fold';
        break;
      case 'call':
        actionColor = Colors.blue;
        actionIcon = '📞';
        actionLabel = 'Call';
        break;
      case 'bet':
        actionColor = Colors.amber;
        actionIcon = '💰';
        actionLabel = 'Bet';
        break;
      case 'raise':
        actionColor = Colors.green;
        actionIcon = '⬆️';
        actionLabel = 'Raise';
        break;
      case 'check':
        actionColor = Colors.grey;
        actionIcon = '✔️';
        actionLabel = 'Check';
        break;
    }

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

    Widget result = box;

    if (actionColor != null && actionLabel != null) {
      final badge = IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: actionColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (actionIcon != null)
                Text(actionIcon!, style: const TextStyle(fontSize: 10)),
              if (actionIcon != null) const SizedBox(width: 2),
              Text(
                actionLabel!,
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ],
          ),
        ),
      );
      result = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(padding: const EdgeInsets.only(bottom: 4), child: badge),
          box,
        ],
      );
    }

    if (isFolded) {
      result = Opacity(opacity: 0.5, child: result);
    }

    if (onLongPress != null) {
      result = Tooltip(message: 'Change player type', child: result);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: result,
      ),
    );
  }
}
