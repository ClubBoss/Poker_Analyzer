import 'package:flutter/material.dart';
import '../../models/player_model.dart';

class PlayerZoneWidget extends StatelessWidget {
  final PlayerModel player;
  final bool isHero;
  final bool isActive;
  final bool isFolded;
  final bool isAllIn;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;
  final double scale;

  const PlayerZoneWidget({
    super.key,
    required this.player,
    this.isHero = false,
    this.isActive = false,
    this.isFolded = false,
    this.isAllIn = false,
    this.onEdit,
    this.onRemove,
    this.onTap,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PlayerAvatar(name: player.name, isHero: isHero, onTap: onTap),
        PlayerStackDisplay(stack: player.stack, bet: player.bet, scale: scale),
        PlayerActionButtons(onEdit: onEdit, onRemove: onRemove, scale: scale),
        PlayerStatusIndicator(isFolded: isFolded, isAllIn: isAllIn),
      ],
    );
  }
}

class PlayerAvatar extends StatelessWidget {
  final String name;
  final bool isHero;
  final VoidCallback? onTap;

  const PlayerAvatar({
    super.key,
    required this.name,
    this.isHero = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isHero ? Colors.purpleAccent : Colors.blueGrey;
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        backgroundColor: color,
        child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
      ),
    );
  }
}

class PlayerStackDisplay extends StatelessWidget {
  final int stack;
  final int bet;
  final double scale;

  const PlayerStackDisplay({
    super.key,
    required this.stack,
    required this.bet,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$stack BB',
          style: TextStyle(color: Colors.white, fontSize: 12 * scale),
        ),
        if (bet > 0)
          Text(
            'Bet $bet',
            style: TextStyle(color: Colors.amber, fontSize: 10 * scale),
          ),
      ],
    );
  }
}

class PlayerActionButtons extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;
  final double scale;

  const PlayerActionButtons({
    super.key,
    this.onEdit,
    this.onRemove,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onEdit != null)
          IconButton(
            iconSize: 16 * scale,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onEdit,
            icon: const Icon(Icons.edit, color: Colors.white),
          ),
        if (onRemove != null)
          IconButton(
            iconSize: 16 * scale,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onRemove,
            icon: const Icon(Icons.close, color: Colors.redAccent),
          ),
      ],
    );
  }
}

class PlayerStatusIndicator extends StatelessWidget {
  final bool isFolded;
  final bool isAllIn;

  const PlayerStatusIndicator({
    super.key,
    this.isFolded = false,
    this.isAllIn = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isFolded) {
      return const Text('FOLDED', style: TextStyle(color: Colors.white));
    }
    if (isAllIn) {
      return const Text('ALL-IN', style: TextStyle(color: Colors.purpleAccent));
    }
    return const SizedBox.shrink();
  }
}
