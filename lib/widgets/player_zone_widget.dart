import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/card_model.dart';
import '../models/player_model.dart';
import '../models/player_zone_action_entry.dart' as pz;
import '../services/action_sync_service.dart';
import 'card_selector.dart';
import 'chip_widget.dart';
import 'current_bet_label.dart';
import 'player_stack_label.dart';
import 'stack_bar_widget.dart';
import 'bet_chip_animation.dart';
import 'move_pot_animation.dart';

final Map<String, _PlayerZoneWidgetState> _playerZoneRegistry = {};

class PlayerZoneWidget extends StatefulWidget {
  final String playerName;
  final String street;
  final String? position;
  final List<CardModel> cards;
  final bool isHero;
  final bool isFolded;
  /// Current bet placed by the player.
  final int currentBet;
  /// Current stack size of the player.
  final int? stackSize;
  final PlayerType playerType;
  final ValueChanged<PlayerType>? onPlayerTypeChanged;
  final bool isActive;
  final bool highlightLastAction;
  final bool showHint;
  final String? actionTagText;
  final void Function(int, CardModel) onCardsSelected;
  /// Starting stack value representing 100% for the stack bar.
  final int maxStackSize;
  final double scale;
  // Stack editing is handled by PlayerInfoWidget

  const PlayerZoneWidget({
    Key? key,
    required this.playerName,
    required this.street,
    this.position,
    required this.cards,
    required this.isHero,
    required this.isFolded,
    this.currentBet = 0,
    this.stackSize,
    this.playerType = PlayerType.unknown,
    this.onPlayerTypeChanged,
    required this.onCardsSelected,
    this.isActive = false,
    this.highlightLastAction = false,
    this.showHint = false,
    this.actionTagText,
    this.maxStackSize = 100,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  State<PlayerZoneWidget> createState() => _PlayerZoneWidgetState();
}

class _PlayerZoneWidgetState extends State<PlayerZoneWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late PlayerType _playerType;
  late int _currentBet;
  late List<CardModel> _cards;
  String? _actionTagText;
  OverlayEntry? _betEntry;
  bool _winnerHighlight = false;
  Timer? _highlightTimer;

  @override
  void initState() {
    super.initState();
    _playerType = widget.playerType;
    _currentBet = widget.currentBet;
    _cards = List<CardModel>.from(widget.cards);
    _actionTagText = widget.actionTagText;
    _playerZoneRegistry[widget.playerName] = this;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PlayerZoneWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playerName != oldWidget.playerName) {
      _playerZoneRegistry.remove(oldWidget.playerName);
      _playerZoneRegistry[widget.playerName] = this;
    }
    if (widget.isActive && !oldWidget.isActive) {
      _controller
        ..reset()
        ..repeat(reverse: true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
      _controller.reset();
    }
    if (widget.playerType != oldWidget.playerType) {
      _playerType = widget.playerType;
    }
    if (widget.cards != oldWidget.cards) {
      _cards = List<CardModel>.from(widget.cards);
    }
    if (widget.currentBet != oldWidget.currentBet) {
      _currentBet = widget.currentBet;
      if (widget.currentBet > 0 && widget.currentBet > oldWidget.currentBet) {
        _playBetAnimation(widget.currentBet);
      }
    }
    if (widget.actionTagText != oldWidget.actionTagText) {
      _actionTagText = widget.actionTagText;
    }
  }

  /// Updates the player's bet value.
  void updateBet(int bet) {
    setState(() => _currentBet = bet);
  }

  /// Updates the player's visible cards.
  void updateCards(List<CardModel> cards) {
    setState(() => _cards = List<CardModel>.from(cards));
  }

  void highlightWinner() {
    _highlightTimer?.cancel();
    setState(() => _winnerHighlight = true);
    _highlightTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _winnerHighlight = false);
    });
  }

  void _playBetAnimation(int amount) {
    final overlay = Overlay.of(context);
    final box = context.findRenderObject() as RenderBox?;
    if (overlay == null || box == null) return;
    final start = box.localToGlobal(box.size.center(Offset.zero));
    final media = MediaQuery.of(context).size;
    final end = Offset(media.width / 2, media.height / 2 - 60 * widget.scale);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => BetChipAnimation(
        start: start,
        end: end,
        amount: amount,
        scale: widget.scale,
        onCompleted: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
    _betEntry = entry;
  }

  @override
  void dispose() {
    _playerZoneRegistry.remove(widget.playerName);
    _highlightTimer?.cancel();
    _betEntry?.remove();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final nameStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 14 * widget.scale,
    );
    final captionStyle = TextStyle(
      color: _getPositionColor(widget.position),
      fontSize: 12 * widget.scale,
      fontWeight: FontWeight.bold,
    );
    final stackStyle = TextStyle(
      color: isDark ? Colors.white70 : Colors.black87,
      fontSize: 12 * widget.scale,
      fontWeight: FontWeight.w500,
    );
    final tagStyle = TextStyle(color: Colors.white, fontSize: 12 * widget.scale);

    final label = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 100 * widget.scale),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8 * widget.scale, vertical: 4 * widget.scale),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(12 * widget.scale),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.playerName,
                  style: nameStyle,
                ),
                Padding(
                  padding: EdgeInsets.only(left: 4.0 * widget.scale),
                  child: Text(
                    _playerTypeIcon(_playerType),
                    style: TextStyle(fontSize: 14 * widget.scale),
                  ),
                ),
                if (widget.isHero)
                  Padding(
                    padding: EdgeInsets.only(left: 4.0 * widget.scale),
                    child: Icon(
                      Icons.star,
                      color: Colors.orangeAccent,
                      size: 14 * widget.scale,
                    ),
                  ),
              ],
            ),
            if (widget.stackSize != null)
              Padding(
                padding: EdgeInsets.only(top: 2.0 * widget.scale),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '🪙',
                      style: TextStyle(fontSize: 12 * widget.scale),
                    ),
                    SizedBox(width: 4 * widget.scale),
                    Text(
                      '${widget.stackSize}',
                      style: stackStyle,
                    ),
                  ],
                ),
              ),
            if (widget.position != null)
              Padding(
                padding: EdgeInsets.only(top: 2.0 * widget.scale),
                child: Text(
                  widget.position!,
                  style: captionStyle,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );

    final labelWithIcon = Stack(
      clipBehavior: Clip.none,
      children: [
        label,
        Positioned(
          top: -4 * widget.scale,
          right: -4 * widget.scale,
          child: AnimatedOpacity(
            opacity: widget.showHint ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: AnimatedScale(
              scale: widget.showHint ? 1.0 : 0.8,
              duration: const Duration(milliseconds: 200),
              child: Tooltip(
                message: 'Нажмите, чтобы ввести действие',
                child: Icon(
                  Icons.edit,
                  size: 16 * widget.scale,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        labelWithIcon,
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          ),
          child: (!widget.isFolded && _currentBet > 0)
              ? Padding(
                  padding: EdgeInsets.only(top: 4 * widget.scale),
                  child: ChipWidget(amount: _currentBet, scale: widget.scale),
                )
              : SizedBox(height: 4 * widget.scale),
        ),
        SizedBox(height: 4 * widget.scale),
        Opacity(
          opacity: widget.isFolded ? 0.4 : 1.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(2, (index) {
              final card = index < _cards.length ? _cards[index] : null;
              final isRed = card?.suit == '♥' || card?.suit == '♦';

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.isHero
                    ? () async {
                        final selected = await showCardSelector(context);
                        if (selected != null) {
                          widget.onCardsSelected(index, selected);
                        }
                      }
                    : null,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 36 * widget.scale,
                  height: 52 * widget.scale,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(card == null ? 0.3 : 1),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 3,
                        offset: const Offset(1, 2),
                      )
                    ],
                  ),
                  alignment: Alignment.center,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: card != null
                        ? Text(
                            '${card.rank}${card.suit}',
                            key: ValueKey('${card.rank}${card.suit}$index'),
                            style: TextStyle(
                              color: isRed ? Colors.red : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 18 * widget.scale,
                            ),
                          )
                        : widget.isHero
                            ? const Icon(Icons.add,
                                color: Colors.grey, key: ValueKey('add'))
                            : Image.asset(
                                'assets/cards/card_back.png',
                                key: const ValueKey('back'),
                                fit: BoxFit.cover,
                              ),
                  ),
                ),
              );
            }),
        ),
      ),
        PlayerStackLabel(stack: widget.stackSize, scale: widget.scale),
        StackBarWidget(
          stack: widget.stackSize,
          maxStack: widget.maxStackSize,
          scale: widget.scale,
        ),
        CurrentBetLabel(bet: _currentBet, scale: widget.scale),
        if (_actionTagText != null)
          Padding(
            padding: EdgeInsets.only(top: 4.0 * widget.scale),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6 * widget.scale, vertical: 2 * widget.scale),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.6),
                borderRadius: BorderRadius.circular(10 * widget.scale),
              ),
              child: Text(
                _actionTagText!,
                style: tagStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );

    final content = Stack(
      clipBehavior: Clip.none,
      children: [
        column,
      ],
    );

    Widget result = content;

    if (widget.isFolded) {
      result = ClipRect(
        child: ColorFiltered(
          colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
          child: Opacity(opacity: 0.6, child: result),
        ),
      );
    }

    result = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.all(2 * widget.scale),
      decoration: (widget.isActive || widget.highlightLastAction)
          ? BoxDecoration(
              border: Border.all(color: Colors.blueAccent, width: 3),
              borderRadius: BorderRadius.circular(12 * widget.scale),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.6),
                  blurRadius: 8,
                )
              ],
            )
          : null,
      child: result,
    );

    if (_winnerHighlight) {
      result = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12 * widget.scale),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.8),
              blurRadius: 20,
              spreadRadius: 4,
            ),
          ],
        ),
        child: result,
      );
    }

    if (widget.isActive) {
      result = FadeTransition(
        opacity: Tween(begin: 0.85, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOutExpo),
        ),
        child: ScaleTransition(
          scale: Tween(begin: 0.96, end: 1.08).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeInOutExpo),
          ),
          child: result,
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: _showPlayerTypeDialog,
      onTap: _handleTap,
      child: result,
    );
  }

  Color _getPositionColor(String? position) {
    switch (position) {
      case 'BTN':
        return Colors.amber;
      case 'SB':
      case 'BB':
        return Colors.blueAccent;
      default:
        return Colors.white70;
    }
  }

  String _playerTypeIcon(PlayerType type) {
    switch (type) {
      case PlayerType.shark:
        return '🦈';
      case PlayerType.fish:
        return '🐠';
      case PlayerType.callingStation:
        return '📞';
      case PlayerType.maniac:
        return '🔥';
      case PlayerType.nit:
        return '🧊';
      case PlayerType.unknown:
      default:
        return '👤';
    }
  }

  String _playerTypeLabel(PlayerType type) {
    switch (type) {
      case PlayerType.shark:
        return 'Shark';
      case PlayerType.fish:
        return 'Fish';
      case PlayerType.callingStation:
        return 'Calling Station';
      case PlayerType.maniac:
        return 'Maniac';
      case PlayerType.nit:
        return 'Nit';
      case PlayerType.unknown:
      default:
        return 'Unknown';
    }
  }

  Future<void> _showPlayerTypeDialog() async {
    PlayerType selected = _playerType;
    final result = await showDialog<PlayerType>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Тип игрока'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: PlayerType.values.map((t) {
              return RadioListTile<PlayerType>(
                title: Text('${_playerTypeIcon(t)}  ${_playerTypeLabel(t)}'),
                value: t,
                groupValue: selected,
                onChanged: (val) => setState(() => selected = val!),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, selected),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      setState(() => _playerType = result);
      widget.onPlayerTypeChanged?.call(result);
    }
  }

  Future<void> _handleTap() async {
    if (widget.isFolded) return;
    final result = await _showActionSheet();
    if (result == null) return;
    final String action = result['action'] as String;
    final int? amount = result['amount'] as int?;
    setState(() {
      _actionTagText = amount != null
          ? '${_capitalize(action)} $amount'
          : _capitalize(action);
      if (amount != null) {
        _currentBet = amount;
      }
    });
    final sync = context.read<ActionSyncService>();
    sync.addOrUpdate(pz.ActionEntry(
      playerName: widget.playerName,
      street: widget.street,
      action: action,
      amount: amount,
    ));
  }

  Future<Map<String, dynamic>?> _showActionSheet() {
    final TextEditingController controller = TextEditingController();
    String? selected;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          final bool needAmount = selected == 'bet' || selected == 'raise';
          return Padding(
            padding: MediaQuery.of(ctx).viewInsets + const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, {'action': 'fold'}),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.black87 : Colors.blueGrey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Fold'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, {'action': 'check'}),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.black87 : Colors.blueGrey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Check'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, {'action': 'call'}),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.black87 : Colors.blueGrey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Call'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setModal(() => selected = 'bet'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.black87 : Colors.blueGrey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Bet'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setModal(() => selected = 'raise'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.black87 : Colors.blueGrey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Raise'),
                ),
                if (needAmount) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.black12,
                      hintText: 'Amount',
                      hintStyle: const TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      final int? amt = int.tryParse(controller.text);
                      if (amt != null) {
                        Navigator.pop(ctx, {
                          'action': selected,
                          'amount': amt,
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark ? Colors.blueGrey : Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Confirm'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    ).whenComplete(controller.dispose);
  }

  String _capitalize(String s) =>
      s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : s;
}

/// Simple fade-in/out "Winner" label displayed over a player zone.
class _WinnerCelebration extends StatefulWidget {
  final Offset position;
  final double scale;
  final VoidCallback? onCompleted;

  const _WinnerCelebration({
    Key? key,
    required this.position,
    this.scale = 1.0,
    this.onCompleted,
  }) : super(key: key);

  @override
  State<_WinnerCelebration> createState() => _WinnerCelebrationState();
}

class _WinnerCelebrationState extends State<_WinnerCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 30,
      ),
      const TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 30,
      ),
    ]).animate(_controller);

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.8, end: 1.2).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1.0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 50,
      ),
    ]).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onCompleted?.call();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: FadeTransition(
        opacity: _opacity,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 8 * widget.scale,
              vertical: 4 * widget.scale,
            ),
            decoration: BoxDecoration(
              color: Colors.amberAccent.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12 * widget.scale),
              boxShadow: const [
                BoxShadow(color: Colors.black45, blurRadius: 6),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.emoji_events,
                  size: 16 * widget.scale,
                  color: Colors.black,
                ),
                SizedBox(width: 4 * widget.scale),
                Text(
                  'Winner!',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14 * widget.scale,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Highlights the [PlayerZoneWidget] for the given [playerName].
/// This should be called before [showWinPotAnimation] to visually
/// indicate the winner.
void showWinnerHighlight(BuildContext context, String playerName) {
  final state = _playerZoneRegistry[playerName];
  state?.highlightWinner();
}

/// Updates and reveals cards for the [PlayerZoneWidget] with the given
/// [playerName].
void revealOpponentCards(String playerName, List<CardModel> cards) {
  final state = _playerZoneRegistry[playerName];
  state?.updateCards(cards);
}

/// Reveals cards for multiple opponents at once. Typically called after
/// [showWinnerHighlight] and before [showWinPotAnimation].
void showOpponentCards(
    BuildContext context, Map<String, List<CardModel>> cardsByPlayer) {
  for (final entry in cardsByPlayer.entries) {
    revealOpponentCards(entry.key, entry.value);
  }
}

/// Animates the central pot moving to the specified player's zone.
void movePotToWinner(BuildContext context, String playerName) {
  final overlay = Overlay.of(context);
  final state = _playerZoneRegistry[playerName];
  if (overlay == null || state == null) return;

  final box = state.context.findRenderObject() as RenderBox?;
  if (box == null) return;

  final end = box.localToGlobal(box.size.center(Offset.zero));
  final media = MediaQuery.of(context).size;
  final start = Offset(media.width / 2, media.height / 2);

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => MovePotAnimation(
      start: start,
      end: end,
      scale: state.widget.scale,
      onCompleted: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

/// Displays a short celebratory overlay over the winning player's zone.
void showWinnerCelebration(BuildContext context, String playerName) {
  final overlay = Overlay.of(context);
  final state = _playerZoneRegistry[playerName];
  if (overlay == null || state == null) return;

  final box = state.context.findRenderObject() as RenderBox?;
  if (box == null) return;

  final pos = box.localToGlobal(box.size.center(Offset.zero));

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _WinnerCelebration(
      position: pos,
      scale: state.widget.scale,
      onCompleted: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

/// Runs the full winner reveal animation sequence.
///
/// This will first highlight the player's zone, optionally reveal
/// their cards, and finally move the pot to the winner.
Future<void> showWinnerSequence(
  BuildContext context,
  String playerName, {
  List<CardModel>? cards,
  bool showCelebration = true,
}) async {
  // Brief delay before showing the highlight.
  await Future.delayed(const Duration(milliseconds: 500));
  showWinnerHighlight(context, playerName);

  // Optionally reveal the winner's cards.
  if (cards != null) {
    await Future.delayed(const Duration(milliseconds: 500));
    revealOpponentCards(playerName, cards);
  }

  // Delay slightly longer before moving the pot.
  await Future.delayed(const Duration(milliseconds: 700));
  movePotToWinner(context, playerName);

  if (showCelebration) {
    await Future.delayed(const Duration(milliseconds: 1000));
    showWinnerCelebration(context, playerName);
  }
}

