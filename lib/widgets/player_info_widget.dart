import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import 'package:intl/intl.dart';
import '../models/card_model.dart';
import 'action_timer_ring.dart';
import 'flip_card.dart';
import 'player_zone/player_stack_value.dart';

/// Compact display for a player's position, stack, tag and last action.
/// Optionally shows a simplified position label as a badge.
class PlayerInfoWidget extends StatelessWidget {
  final String position;
  final int stack;
  final String tag;
  final List<CardModel> cards;
  /// Last action taken by the player ('fold', 'call', 'bet', 'raise', 'check').
  final String? lastAction;
  final bool isActive;
  final bool isFolded;
  final bool isHero;
  final bool isOpponent;
  /// Reveal hole cards with a flip animation when true.
  final bool revealCards;
  final String playerTypeIcon;
  /// Text label describing the player's type.
  final String? playerTypeLabel;
  /// Simplified position label shown as a badge.
  final String? positionLabel;
  /// Shows 'SB' or 'BB' badge when the player is in the blinds.
  final String? blindLabel;
  /// Whether to show an indicator that this player made the last action.
  final bool showLastIndicator;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  /// Called when the edit icon is tapped.
  final VoidCallback? onEdit;
  /// Called when the stack value has been edited and confirmed.
  final ValueChanged<int>? onStackTap;
  /// Called when the remove icon is tapped.
  final VoidCallback? onRemove;
  /// Called when the active timer finishes.
  final VoidCallback? onTimeExpired;
  /// Called when a card slot is tapped. The index corresponds to 0 or 1.
  final void Function(int index)? onCardTap;
  /// Amount invested by the player on the current street.
  final int streetInvestment;
  /// Last bet amount placed by the player on the current street.
  final int currentBet;
  /// Remaining stack after subtracting investments.
  final int? remainingStack;
  /// Disables the active timer when true.
  final bool timersDisabled;
  /// True when the player has no stack left after an all-in.
  final bool isBust;

  const PlayerInfoWidget({
    super.key,
    required this.position,
    required this.stack,
    required this.tag,
    this.cards = const [],
    this.lastAction,
    this.isActive = false,
    this.isFolded = false,
    this.isHero = false,
    this.isOpponent = false,
    this.revealCards = false,
    this.playerTypeIcon = '',
    this.playerTypeLabel,
    this.positionLabel,
    this.blindLabel,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onEdit,
    this.onStackTap,
    this.onRemove,
    this.onTimeExpired,
    this.onCardTap,
    this.streetInvestment = 0,
    this.currentBet = 0,
    this.showLastIndicator = false,
    this.remainingStack,
    this.timersDisabled = false,
    this.isBust = false,
  });

  String _formatStack(int value) {
    if (value >= 1000) {
      final double thousands = value / 1000.0;
      return '${thousands.toStringAsFixed(thousands >= 10 ? 0 : 1)}K';
    }
    return value.toString();
  }

  String _format(int value) => NumberFormat.decimalPattern().format(value);

  @override
  Widget build(BuildContext context) {
    const stackStyle = TextStyle(color: Colors.white70, fontSize: 12);
    final borderColor = isActive
        ? AppColors.accent
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

    final Widget box = Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: borderColor ?? Colors.white24, width: borderColor != null ? 2 : 1),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 2)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                position,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isHero)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '🧙‍♂️ Hero',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
              if (isOpponent)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Opponent',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
              if (blindLabel != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      blindLabel!,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
          if (remainingStack != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: AnimatedOpacity(
                opacity: isBust ? 0.3 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: Text(
                  'Осталось: ${_formatStack(remainingStack!)} BB',
                  style: stackStyle.copyWith(
                    color: isBust ? Colors.grey : stackStyle.color,
                  ),
                ),
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
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(2, (idx) {
                final card = idx < cards.length ? cards[idx] : null;
                final isRed = card?.suit == '♥' || card?.suit == '♦';
                return GestureDetector(
                  onTap: onCardTap != null ? () => onCardTap!(idx) : null,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 22,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: card == null ? 0.3 : 1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: card == null
                        ? (isHero
                            ? const Icon(Icons.add,
                                size: 14, color: Colors.grey)
                            : Image.asset('assets/cards/card_back.png'))
                        : FlipCard(
                            width: 22,
                            height: 30,
                            showFront: isHero || revealCards,
                            front: Text(
                              '${card.rank}${card.suit}',
                              style: TextStyle(
                                color: isRed ? Colors.red : Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            back: Image.asset('assets/cards/card_back.png'),
                          ),
                  ),
                );
              }),
            ),
          ),
          if (currentBet > 0)
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                margin: const EdgeInsets.only(top: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '💰 ${_format(currentBet)}',
                  style:
                      const TextStyle(color: Colors.black, fontSize: 10),
                ),
              ),
            ),
          if (streetInvestment > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.circle,
                    size: 12,
                    color: AppColors.accent.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '$streetInvestment',
                    style: TextStyle(
                      color: AppColors.accent.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () async {
              if (onStackTap == null) return;
              final controller = TextEditingController(text: stack.toString());
              int? value = stack;
              final result = await showDialog<int>(
                context: context,
                builder: (context) => StatefulBuilder(
                  builder: (context, setState) {
                    return AlertDialog(
                      backgroundColor: Colors.black.withValues(alpha: 0.3),
                      title: const Text(
                        'Edit Stack',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: TextField(
                        controller: controller,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white10,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          hintText: 'Enter stack',
                          hintStyle: const TextStyle(color: Colors.white70),
                        ),
                        onChanged: (text) {
                          setState(() => value = int.tryParse(text));
                        },
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: value != null && value! > 0
                              ? () => Navigator.pop(context, value)
                              : null,
                          child: const Text('OK'),
                        ),
                      ],
                    );
                  },
                ),
              );
              if (result != null && result > 0) {
                onStackTap!(result);
              }
            },
          child: PlayerStackValue(
            stack: stack,
            scale: 0.8,
            isBust: isBust,
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
                actionLabel,
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );

    Widget result = box;



    if (isFolded) {
      result = ClipRect(
        child: ColorFiltered(
          colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
          child: Opacity(opacity: 0.4, child: result),
        ),
      );
    }

    if (onEdit != null || onLongPress != null) {
      result = Tooltip(message: 'Edit player', child: result);
    }

    Widget clickable = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        onLongPress: onLongPress ?? onEdit,
        borderRadius: BorderRadius.circular(8),
        child: result,
      ),
    );

    if (isActive) {
      clickable = _ActivePlayerGlow(child: clickable);
      clickable = ActionTimerRing(
        isActive: !timersDisabled,
        onTimeExpired: timersDisabled ? null : onTimeExpired,
        child: clickable,
      );
    }

    Widget withBadge = clickable;
    if (playerTypeIcon.isNotEmpty || onRemove != null || onEdit != null || showLastIndicator) {
      final children = <Widget>[clickable];
      if (playerTypeIcon.isNotEmpty) {
        children.add(Positioned(
          bottom: -6,
          right: -6,
          child: IgnorePointer(
            child: Text(
              playerTypeIcon,
              style: const TextStyle(
                fontSize: 12,
                shadows: [Shadow(color: Colors.black, blurRadius: 2)],
              ),
            ),
          ),
        ));
      }
      if (onEdit != null) {
        children.add(Positioned(
          top: 0,
          left: 0,
          child: GestureDetector(
            onTap: onEdit,
            child: const Text('✏️', style: TextStyle(fontSize: 12)),
          ),
        ));
      }
      if (onRemove != null) {
        children.add(Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: onRemove,
            child: const Text('❌', style: TextStyle(fontSize: 12)),
          ),
        ));
      }
      if (showLastIndicator) {
        children.add(Positioned(
          bottom: -6,
          left: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '⚡',
              style: TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
        ));
      }
      withBadge = Stack(clipBehavior: Clip.none, children: children);
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
                color: Colors.orange.withValues(alpha: 0.5 + (t * 0.3)),
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
