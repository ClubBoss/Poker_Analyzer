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

class PlayerAvatar extends StatefulWidget {
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
  State<PlayerAvatar> createState() => _PlayerAvatarState();
}

class _PlayerAvatarState extends State<PlayerAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _anim = Tween(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    if (widget.isHero) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant PlayerAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHero && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isHero && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isHero ? Colors.purpleAccent : Colors.blueGrey;
    final avatar = CircleAvatar(
      backgroundColor: color,
      child: Text(widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?'),
    );
    if (!widget.isHero) {
      return GestureDetector(onTap: widget.onTap, child: avatar);
    }
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, child) {
          return Transform.scale(
            scale: _anim.value,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFD700), width: 3),
              ),
              child: child,
            ),
          );
        },
        child: avatar,
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
