import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../models/action_entry.dart';
import 'player_zone_widget.dart';

class PlayerInfoWidget extends StatelessWidget {
  final String playerName;
  final String? position;
  final List<CardModel> cards;
  final bool isHero;
  final bool isFolded;
  final bool isActive;
  final bool highlightLastAction;
  final bool showHint;
  final String? actionTagText;
  final Function(CardModel) onCardsSelected;
  final double scale;
  final String playerTypeIcon;
  final int stack;
  final ActionEntry? lastAction;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onStackTap;

  const PlayerInfoWidget({
    super.key,
    required this.playerName,
    this.position,
    required this.cards,
    required this.isHero,
    required this.isFolded,
    required this.onCardsSelected,
    required this.stack,
    this.isActive = false,
    this.highlightLastAction = false,
    this.showHint = false,
    this.actionTagText,
    this.scale = 1.0,
    this.playerTypeIcon = '🔘',
    this.lastAction,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onStackTap,
  });

  Color _actionColor(String action) {
    switch (action) {
      case 'fold':
        return Colors.red[700]!;
      case 'call':
        return Colors.blue[700]!;
      case 'raise':
        return Colors.green[600]!;
      case 'bet':
        return Colors.amber[700]!;
      case 'check':
        return Colors.grey[700]!;
      default:
        return Colors.black;
    }
  }

  Color _actionTextColor(String action) {
    return action == 'bet' ? Colors.black : Colors.white;
  }

  IconData? _actionIcon(String action) {
    switch (action) {
      case 'fold':
        return Icons.close;
      case 'call':
        return Icons.call;
      case 'raise':
        return Icons.arrow_upward;
      case 'bet':
        return Icons.trending_up;
      case 'check':
        return Icons.remove;
      default:
        return null;
    }
  }

  String _actionLabel(ActionEntry entry) {
    return entry.amount != null
        ? '${entry.action} ${entry.amount}'
        : entry.action;
  }

  @override
  Widget build(BuildContext context) {
    final zone = GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      onLongPress: onLongPress,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlayerZoneWidget(
            scale: scale,
            playerName: playerName,
            position: position,
            cards: cards,
            isHero: isHero,
            isFolded: isFolded,
            isActive: isActive,
            highlightLastAction: highlightLastAction,
            showHint: showHint,
            actionTagText: actionTagText,
            onCardsSelected: onCardsSelected,
          ),
          SizedBox(width: 4 * scale),
          Text(playerTypeIcon, style: TextStyle(fontSize: 18 * scale)),
        ],
      ),
    );

    final actionWidget = (lastAction != null &&
            (lastAction!.action == 'bet' ||
                lastAction!.action == 'raise' ||
                lastAction!.action == 'call') &&
            lastAction!.amount != null)
        ? Container(
            key: ValueKey('${lastAction!.action}_${lastAction!.amount}'),
            padding: EdgeInsets.symmetric(
                horizontal: 10 * scale, vertical: 6 * scale),
            decoration: BoxDecoration(
              color: _actionColor(lastAction!.action),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_actionIcon(lastAction!.action) != null) ...[
                  Icon(
                    _actionIcon(lastAction!.action),
                    size: 14 * scale,
                    color: _actionTextColor(lastAction!.action),
                  ),
                  SizedBox(width: 4 * scale),
                ],
                Text(
                  _actionLabel(lastAction!),
                  style: TextStyle(
                    color: _actionTextColor(lastAction!.action),
                    fontSize: 13 * scale,
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();

    final stackChip = GestureDetector(
      onTap: onStackTap,
      child: _StackChip(key: ValueKey(stack), amount: stack, scale: scale),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        zone,
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          ),
          child: actionWidget,
        ),
        SizedBox(height: 4 * scale),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          ),
          child: stackChip,
        ),
      ],
    );
  }
}

class _StackChip extends StatelessWidget {
  final int amount;
  final double scale;

  const _StackChip({super.key, required this.amount, this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32 * scale,
      height: 32 * scale,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.orangeAccent, Colors.deepOrange.shade700],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 4 * scale,
          ),
        ],
      ),
      child: Text(
        '$amount',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14 * scale,
        ),
      ),
    );
  }
}
