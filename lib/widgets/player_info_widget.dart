import 'package:flutter/material.dart';

/// Compact display for a player's position, stack, tag and last action.
/// Optionally shows a simplified position label as a badge.
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
  /// Text label describing the player's type.
  final String? playerTypeLabel;
  /// Simplified position label shown as a badge.
  final String? positionLabel;
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
    this.playerTypeIcon = '',
    this.playerTypeLabel,
    this.positionLabel,
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
    String? actionLabel;
    switch (lastAction) {
      case 'fold':
        actionColor = Colors.red;
        actionLabel = 'Fold';
        break;
      case 'call':
        actionColor = Colors.blue;
        actionLabel = 'Call';
        break;
      case 'bet':
        actionColor = Colors.amber;
        actionLabel = 'Bet';
        break;
      case 'raise':
        actionColor = Colors.green;
        actionLabel = 'Raise';
        break;
      case 'check':
        actionColor = Colors.grey;
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
          if (positionLabel != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  positionLabel!,
                  style:
                      const TextStyle(color: Colors.white, fontSize: 10),
                ),
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
            child: Column(
              children: [
                if (playerTypeIcon.isNotEmpty)
                  Text(playerTypeIcon, style: const TextStyle(fontSize: 14)),
                if (playerTypeLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      playerTypeLabel!,
                      style: const TextStyle(color: Colors.white60, fontSize: 10),
                    ),
                  ),
              ],
            ),
          ),
          if (actionColor != null && actionLabel != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: actionColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );

    Widget result = box;

    if (isFolded) {
      result = Opacity(opacity: 0.5, child: result);
    }

    if (onLongPress != null) {
      result = Tooltip(message: 'Change player type', child: result);
    }

    Widget clickable = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: result,
      ),
    );

    if (isActive) {
      clickable = _ActivePlayerGlow(child: clickable);
    }

    Widget withBadge = clickable;
    if (playerTypeIcon.isNotEmpty) {
      withBadge = Stack(
        clipBehavior: Clip.none,
        children: [
          clickable,
          Positioned(
            top: -6,
            right: -6,
            child: IgnorePointer(
              child: Text(
                playerTypeIcon,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      );
    }

    return withBadge;
  }
}

class _ActivePlayerGlow extends StatefulWidget {
  final Widget child;
  const _ActivePlayerGlow({required this.child});

  @override
  State<_ActivePlayerGlow> createState() => _ActivePlayerGlowState();
}

class _ActivePlayerGlowState extends State<_ActivePlayerGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.5 + (t * 0.3)),
                blurRadius: 8 + (8 * t),
                spreadRadius: 1,
              ),
            ],
            borderRadius: BorderRadius.circular(8),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
