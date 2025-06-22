import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../helpers/table_geometry_helper.dart';
import '../models/card_model.dart';
import '../models/player_model.dart';
import '../models/player_zone_action_entry.dart' as pz;
import '../models/action_outcome.dart';
import '../services/action_sync_service.dart';
import '../services/transition_lock_service.dart';
import '../services/pot_animation_service.dart';
import '../services/pot_sync_service.dart';
import '../user_preferences.dart';
import 'card_selector.dart';
import 'chip_widget.dart';
import 'current_bet_label.dart';
import 'bet_size_label.dart';
import 'player_stack_value.dart';
import 'stack_bar_widget.dart';
import 'bet_flying_chips.dart';
import 'chip_stack_moving_widget.dart';
import 'chip_moving_widget.dart';
import 'bet_to_center_animation.dart';
import 'move_pot_animation.dart';
import 'winner_zone_highlight.dart';
import 'loss_amount_widget.dart';
import 'gain_amount_widget.dart';

final Map<String, _PlayerZoneWidgetState> playerZoneRegistry = {};

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
  /// Map of stack sizes keyed by player index.
  final Map<int, int>? stackSizes;
  /// Index of this player within the stack map.
  final int? playerIndex;
  final PlayerType playerType;
  final ValueChanged<PlayerType>? onPlayerTypeChanged;
  final bool isActive;
  final bool highlightLastAction;
  final bool showHint;
  /// Whether to display the player type label under the stack.
  final bool showPlayerTypeLabel;
  /// Player's remaining stack after subtracting investments.
  final int? remainingStack;
  final String? actionTagText;
  final void Function(int, CardModel) onCardsSelected;
  /// Starting stack value representing 100% for the stack bar.
  final int maxStackSize;
  final double scale;
  final Set<String> usedCards;
  final bool editMode;
  final PlayerModel player;
  final ValueChanged<int>? onStackChanged;
  final ValueChanged<int>? onBetChanged;
  // Stack editing is handled by PlayerInfoWidget

  /// Returns the offset of a seat around an elliptical poker table. This is
  /// based on the size of the table widget and indexes players so that index 0
  /// (hero) sits at the bottom center.
  static Offset seatPosition(
      int index, int playerCount, Size tableSize) {
    return TableGeometryHelper.positionForPlayer(
        index, playerCount, tableSize.width, tableSize.height);
  }

  const PlayerZoneWidget({
    Key? key,
    required this.player,
    required this.playerName,
    required this.street,
    this.position,
    required this.cards,
    required this.isHero,
    required this.isFolded,
    this.currentBet = 0,
    this.stackSize,
    this.stackSizes,
    this.playerIndex,
    this.playerType = PlayerType.unknown,
    this.onPlayerTypeChanged,
    required this.onCardsSelected,
    this.isActive = false,
    this.highlightLastAction = false,
    this.showHint = false,
    this.showPlayerTypeLabel = false,
    this.remainingStack,
    this.actionTagText,
    this.maxStackSize = 100,
    this.scale = 1.0,
    this.usedCards = const {},
    this.editMode = false,
    this.onStackChanged,
    this.onBetChanged,
  }) : super(key: key);

  @override
  State<PlayerZoneWidget> createState() => _PlayerZoneWidgetState();
}

class _PlayerZoneWidgetState extends State<PlayerZoneWidget>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late PlayerType _playerType;
  late int _currentBet;
  late List<CardModel> _cards;
  int? _stack;
  int? _remainingStack;
  String? _actionTagText;
  OverlayEntry? _betEntry;
  OverlayEntry? _betOverlayEntry;
  OverlayEntry? _actionLabelEntry;
  OverlayEntry? _refundMessageEntry;
  OverlayEntry? _lossAmountEntry;
  OverlayEntry? _gainAmountEntry;
  bool _winnerHighlight = false;
  Timer? _highlightTimer;
  bool _refundGlow = false;
  Timer? _refundGlowTimer;
  String? _lastActionText;
  Color _lastActionColor = Colors.black87;
  double _lastActionOpacity = 0.0;
  Timer? _lastActionTimer;
  int? _stackBetAmount;
  Color _stackBetColor = Colors.amber;
  Timer? _stackBetTimer;
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;
  late TextEditingController _stackController;
  late TextEditingController _betController;
  late final AnimationController _foldController;
  late final Animation<Offset> _foldOffset;
  late final Animation<double> _foldOpacity;
  bool _showCards = true;

  @override
  void initState() {
    super.initState();
    _playerType = widget.playerType;
    _currentBet = widget.player.bet;
    _cards = List<CardModel>.from(widget.cards);
    _actionTagText = widget.actionTagText;
    _stack = widget.player.stack;
    if (widget.stackSize != null) {
      _stack = widget.stackSize;
    } else if (widget.stackSizes != null && widget.playerIndex != null) {
      _stack = widget.stackSizes![widget.playerIndex!];
    }
    if (widget.currentBet != 0) {
      _currentBet = widget.currentBet;
    }
    _remainingStack = widget.remainingStack;
    playerZoneRegistry[widget.playerName] = this;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.1)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.1, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_bounceController);
    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
    _stackController = TextEditingController(text: _stack?.toString() ?? '');
    _betController = TextEditingController(text: '$_currentBet');
    _foldController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (mounted) setState(() => _showCards = false);
        }
      });
    _foldOffset = Tween<Offset>(begin: Offset.zero, end: const Offset(-0.6, 0.8))
        .animate(CurvedAnimation(parent: _foldController, curve: Curves.easeIn));
    _foldOpacity = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _foldController, curve: Curves.easeIn));
    if (widget.isFolded) {
      _showCards = false;
    }
  }

  @override
  void didUpdateWidget(covariant PlayerZoneWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playerName != oldWidget.playerName) {
      playerZoneRegistry.remove(oldWidget.playerName);
      playerZoneRegistry[widget.playerName] = this;
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
    if (widget.isFolded && !oldWidget.isFolded) {
      setState(() {
        _showCards = true;
      });
      _foldController.forward(from: 0.0);
    } else if (!widget.isFolded && oldWidget.isFolded) {
      _foldController.reset();
      setState(() => _showCards = true);
    }
    if (widget.player.bet != oldWidget.player.bet ||
        widget.currentBet != oldWidget.currentBet) {
      _currentBet = widget.player.bet;
      if (widget.currentBet != oldWidget.currentBet) {
        final delta = widget.currentBet - oldWidget.currentBet;
        if (delta > 0) {
          _playBetAnimation(delta);
        } else if (delta < 0) {
          _playBetRefundAnimation(-delta);
        }
      }
      _betController.text = '$_currentBet';
    }
    if (widget.actionTagText != oldWidget.actionTagText) {
      _actionTagText = widget.actionTagText;
    }
    final int? oldStack = oldWidget.stackSize ??
        (oldWidget.stackSizes != null && oldWidget.playerIndex != null
            ? oldWidget.stackSizes![oldWidget.playerIndex!]
            : null);
    final int? newStack = widget.stackSize ??
        (widget.stackSizes != null && widget.playerIndex != null
            ? widget.stackSizes![widget.playerIndex!]
            : widget.player.stack);
    if (newStack != oldStack) {
      setState(() => _stack = newStack);
      _stackController.text = _stack?.toString() ?? '';
    }
    if (widget.remainingStack != oldWidget.remainingStack) {
      setState(() => _remainingStack = widget.remainingStack);
    }
  }

  /// Updates the player's bet value.
  void updateBet(int bet) {
    setState(() => _currentBet = bet);
  }

  /// Updates the player's visible cards.
  void updateCards(List<CardModel> cards) {
    setState(() => _cards = List<CardModel>.from(cards));
    if (!widget.isHero) {
      _showCardRevealOverlay();
    }
  }

  void highlightWinner() {
    _highlightTimer?.cancel();
    setState(() => _winnerHighlight = true);
    _highlightTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _winnerHighlight = false);
    });
  }

  void clearWinnerHighlight() {
    _highlightTimer?.cancel();
    if (_winnerHighlight) {
      setState(() => _winnerHighlight = false);
    }
  }

  void showRefundGlow() {
    _refundGlowTimer?.cancel();
    setState(() => _refundGlow = true);
    _refundGlowTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _refundGlow = false);
    });
  }

  Future<void> playWinnerBounce() async {
    await _bounceController.forward(from: 0.0);
  }

  /// Returns the display color for a last action label.
  Color _lastActionColorFor(String action) {
    switch (action.toLowerCase()) {
      case 'push':
      case 'all-in':
        return Colors.red;
      case 'call':
        return Colors.blue;
      case 'check':
        return Colors.grey;
      case 'raise':
        return Colors.orange;
      case 'fold':
        return Colors.grey.shade800;
      default:
        return Colors.black87;
    }
  }

  void setLastAction(String text, Color color, String action, [int? amount]) {
    _lastActionTimer?.cancel();
    final labelColor = _lastActionColorFor(action);
    setState(() {
      _lastActionText = text;
      _lastActionColor = labelColor;
      _lastActionOpacity = 1.0;
    });
    _showActionLabel(text, labelColor);
    _lastActionTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _lastActionOpacity = 0.0);
      }
    });
    if (amount != null) {
      showBetOverlay(amount, color);
      if (action == 'bet' || action == 'raise' || action == 'call') {
        playBetChipsToCenter(amount, color: color);
      }
      if (action == 'bet' || action == 'raise') {
        _showStackBetDisplay(amount, color);
      }
    }
  }

  void setLastActionOutcome(ActionOutcome outcome) {
    Color color;
    int? lostAmount;
    int? gainAmount;
    switch (outcome) {
      case ActionOutcome.win:
        color = Colors.green;
        if (_stack != null && _stack! > widget.maxStackSize) {
          gainAmount = _stack! - widget.maxStackSize;
        }
        break;
      case ActionOutcome.lose:
        color = Colors.red;
        if (_stack != null && widget.maxStackSize > _stack!) {
          lostAmount = widget.maxStackSize - _stack!;
        }
        break;
      case ActionOutcome.neutral:
      default:
        color = Colors.white;
    }
    if (mounted) {
      setState(() => _lastActionColor = color);
      if (lostAmount != null && lostAmount > 0) {
        _showLossAmount(lostAmount!);
      }
      if (gainAmount != null && gainAmount > 0) {
        _showGainAmount(gainAmount!);
      }
    }
  }

  void _showCardRevealOverlay() {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _CardRevealBackdrop(
        onCompleted: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  void _playBetAnimation(int amount) {
    final overlay = Overlay.of(context);
    final box = context.findRenderObject() as RenderBox?;
    if (overlay == null || box == null) return;
    final start =
        box.localToGlobal(Offset(box.size.width / 2, 20 * widget.scale));
    final media = MediaQuery.of(context).size;
    final end = Offset(media.width / 2, media.height / 2 - 60 * widget.scale);
    final control = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2 -
          (40 + ChipStackMovingWidget.activeCount * 8) * widget.scale,
    );
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => BetFlyingChips(
        start: start,
        end: end,
        control: control,
        amount: amount,
        color: Colors.amber,
        scale: widget.scale,
        onCompleted: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
    _betEntry = entry;
  }

  void _playBetRefundAnimation(int amount) {
    final overlay = Overlay.of(context);
    final box = context.findRenderObject() as RenderBox?;
    if (overlay == null || box == null) return;
    final media = MediaQuery.of(context).size;
    final start = Offset(media.width / 2, media.height / 2 - 60 * widget.scale);
    final end =
        box.localToGlobal(Offset(box.size.width / 2, 20 * widget.scale));
    final control = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2 -
          (40 + ChipStackMovingWidget.activeCount * 8) * widget.scale,
    );
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => BetFlyingChips(
        start: start,
        end: end,
        control: control,
        amount: amount,
        color: Colors.amber,
        scale: widget.scale,
        onCompleted: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
    _betEntry = entry;
  }

  /// Animates this player's bet flying toward the center pot.
  void playBetChipsToCenter(int amount, {Color color = Colors.amber}) {
    final overlay = Overlay.of(context);
    final box = context.findRenderObject() as RenderBox?;
    if (overlay == null || box == null) return;
    final start =
        box.localToGlobal(Offset(box.size.width / 2, 20 * widget.scale));
    final media = MediaQuery.of(context).size;
    final end = Offset(media.width / 2, media.height / 2 - 60 * widget.scale);
    final control = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2 -
          (40 + ChipStackMovingWidget.activeCount * 8) * widget.scale,
    );
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => BetToCenterAnimation(
        start: start,
        end: end,
        control: control,
        amount: amount,
        color: color,
        scale: widget.scale,
        fadeStart: 0.8,
        labelStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14 * widget.scale,
          shadows: const [Shadow(color: Colors.black54, blurRadius: 2)],
        ),
        onCompleted: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  void showBetOverlay(int amount, Color color) {
    _betOverlayEntry?.remove();
    final overlay = Overlay.of(context);
    final box = context.findRenderObject() as RenderBox?;
    if (overlay == null || box == null) return;
    final pos = box.localToGlobal(Offset(box.size.width / 2, -16 * widget.scale));
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _BetAmountOverlay(
        position: pos,
        amount: amount,
        color: color,
        scale: widget.scale,
        onCompleted: () {
          entry.remove();
          if (_betOverlayEntry == entry) _betOverlayEntry = null;
        },
      ),
    );
    overlay.insert(entry);
    _betOverlayEntry = entry;
  }

  void showRefundMessage(int amount) {
    _refundMessageEntry?.remove();
    final overlay = Overlay.of(context);
    final box = context.findRenderObject() as RenderBox?;
    if (overlay == null || box == null) return;
    final pos =
        box.localToGlobal(Offset(box.size.width / 2, -16 * widget.scale));
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _RefundMessageOverlay(
        position: pos,
        amount: amount,
        scale: widget.scale,
        onCompleted: () {
          entry.remove();
          if (_refundMessageEntry == entry) _refundMessageEntry = null;
        },
      ),
    );
    overlay.insert(entry);
    _refundMessageEntry = entry;
  }

  void _showLossAmount(int amount) {
    _lossAmountEntry?.remove();
    final overlay = Overlay.of(context);
    final box = context.findRenderObject() as RenderBox?;
    if (overlay == null || box == null) return;
    final pos = box.localToGlobal(Offset(box.size.width / 2, -16 * widget.scale));
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => LossAmountWidget(
        position: pos,
        amount: amount,
        scale: widget.scale,
        onCompleted: () {
          entry.remove();
          if (_lossAmountEntry == entry) _lossAmountEntry = null;
        },
      ),
    );
    overlay.insert(entry);
    _lossAmountEntry = entry;
  }

  void _showGainAmount(int amount) {
    _gainAmountEntry?.remove();
    final overlay = Overlay.of(context);
    final box = context.findRenderObject() as RenderBox?;
    if (overlay == null || box == null) return;
    final pos = box.localToGlobal(Offset(box.size.width / 2, -16 * widget.scale));
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => GainAmountWidget(
        position: pos,
        amount: amount,
        scale: widget.scale,
        onCompleted: () {
          entry.remove();
          if (_gainAmountEntry == entry) _gainAmountEntry = null;
        },
      ),
    );
    overlay.insert(entry);
    _gainAmountEntry = entry;
  }

  void _showActionLabel(String text, Color color) {
    _actionLabelEntry?.remove();
    final overlay = Overlay.of(context);
    final box = context.findRenderObject() as RenderBox?;
    if (overlay == null || box == null) return;
    final pos = box.localToGlobal(Offset(box.size.width / 2, -32 * widget.scale));
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ActionLabelOverlay(
        position: pos,
        text: text,
        color: color,
        scale: widget.scale,
        onCompleted: () {
          entry.remove();
          if (_actionLabelEntry == entry) _actionLabelEntry = null;
        },
      ),
    );
    overlay.insert(entry);
    _actionLabelEntry = entry;
  }

  void _showStackBetDisplay(int amount, Color color) {
    _stackBetTimer?.cancel();
    setState(() {
      _stackBetAmount = amount;
      _stackBetColor = color;
    });
    _stackBetTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _stackBetAmount = null);
      }
    });
  }

  /// Animates a stack of chips flying from the center pot to this player.
  void playWinChipsAnimation(int amount) {
    final overlay = Overlay.of(context);
    final box = context.findRenderObject() as RenderBox?;
    if (overlay == null || box == null) return;
    final media = MediaQuery.of(context).size;
    final start = Offset(media.width / 2, media.height / 2 - 60 * widget.scale);
    final end = box.localToGlobal(box.size.center(Offset.zero));
    final control = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2 -
          (40 + ChipMovingWidget.activeCount * 8) * widget.scale,
    );
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => ChipMovingWidget(
        start: start,
        end: end,
        control: control,
        amount: amount,
        color: Colors.orangeAccent,
        scale: widget.scale,
        onCompleted: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  /// Smoothly increases this player's stack by [amount].
  Future<void> animateStackIncrease(int amount) async {
    if (_stack == null) return;
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    final animation = IntTween(begin: _stack!, end: _stack! + amount).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    )..addListener(() {
        if (mounted) {
          setState(() => _stack = animation.value);
        }
      });
    await controller.forward();
    controller.dispose();
  }

  Future<void> _editStack() async {
    final controller = TextEditingController(text: _stack?.toString() ?? '');
    int? value = _stack;
    final result = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.3),
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
              hintText: 'Enter stack in BB',
              hintStyle: const TextStyle(color: Colors.white70),
            ),
            onChanged: (text) => setState(() => value = int.tryParse(text)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed:
                  value != null && value! > 0 ? () => Navigator.pop(context, value) : null,
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
    if (result != null && result > 0) {
      setState(() => _stack = result);
    }
  }

  Widget _betIndicator(TextStyle style) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4 * widget.scale),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🪙', style: TextStyle(fontSize: 12 * widget.scale)),
          SizedBox(width: 4 * widget.scale),
          Text('$_currentBet', style: style),
        ],
      ),
    );
  }

  Widget _betChip(TextStyle style) {
    final double radius = 12 * widget.scale;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: _currentBet > 0
          ? Container(
              key: ValueKey(_currentBet),
              width: radius * 2,
              height: radius * 2,
              margin: EdgeInsets.symmetric(horizontal: 4 * widget.scale),
              decoration: BoxDecoration(
                color: Colors.yellowAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 3 * widget.scale,
                    offset: const Offset(1, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '$_currentBet',
                style: style.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : SizedBox(width: radius * 2, height: radius * 2),
    );
  }

  Widget _effectiveStackLabel(TextStyle style) {
    final potSync = context.watch<PotSyncService>();
    final eff = potSync.effectiveStacks[widget.street];
    final effText = eff != null ? eff.toDouble().toStringAsFixed(1) : '--';
    final platform = Theme.of(context).platform;
    final isMobile =
        platform == TargetPlatform.android || platform == TargetPlatform.iOS;
    return Tooltip(
      triggerMode:
          isMobile ? TooltipTriggerMode.longPress : TooltipTriggerMode.hover,
      message:
          'Эффективный стек — минимальный стек между вами и соперником. Используется при пуш/фолд.',
      child: Text(
        'Eff. stack: $effText BB',
        style: style,
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  void dispose() {
    playerZoneRegistry.remove(widget.playerName);
    _highlightTimer?.cancel();
    _lastActionTimer?.cancel();
    _stackBetTimer?.cancel();
    _betEntry?.remove();
    _betOverlayEntry?.remove();
    _actionLabelEntry?.remove();
    _refundMessageEntry?.remove();
    _lossAmountEntry?.remove();
    _gainAmountEntry?.remove();
    _stackController.dispose();
    _betController.dispose();
    _controller.dispose();
    _bounceController.dispose();
    _foldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final int? stack = _stack;
    final int? remaining = _remainingStack;
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
      color: Colors.white70,
      fontSize: 10 * widget.scale,
      fontWeight: FontWeight.w500,
    );
    final betStyle = TextStyle(
      color: Colors.white70,
      fontSize: 12 * widget.scale,
      fontWeight: FontWeight.w600,
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
                GestureDetector(
                  onLongPressStart: (d) => _showPlayerTypeMenu(d.globalPosition),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.only(left: 4.0 * widget.scale),
                    child: Text(
                      _playerTypeIcon(_playerType),
                      style: TextStyle(fontSize: 14 * widget.scale),
                    ),
                  ),
                ),
                if (widget.isHero)
                  Padding(
                    padding: EdgeInsets.only(left: 4.0 * widget.scale),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 4 * widget.scale, vertical: 2 * widget.scale),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent,
                        borderRadius: BorderRadius.circular(6 * widget.scale),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orangeAccent.withOpacity(0.6),
                            blurRadius: 4 * widget.scale,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 12 * widget.scale,
                          ),
                          SizedBox(width: 2 * widget.scale),
                          Text(
                            'Hero',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10 * widget.scale,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            if (!widget.isFolded && remaining != null)
              Padding(
                padding: EdgeInsets.only(top: 2.0 * widget.scale),
                child: Text(
                  'Осталось: $remaining',
                  style: stackStyle,
                  textAlign: TextAlign.center,
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
            if (stack != null)
              Padding(
                padding: EdgeInsets.only(top: 2.0 * widget.scale),
                child: Text(
                  '$stack BB',
                  style: stackStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            Padding(
              padding: EdgeInsets.only(top: 2.0 * widget.scale),
              child: _effectiveStackLabel(stackStyle),
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

    final labelRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isLeftSide(widget.position)) _betChip(betStyle),
        labelWithIcon,
        if (!_isLeftSide(widget.position)) _betChip(betStyle),
      ],
    );

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        labelRow,
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
            children: [
              if (_currentBet > 0 && _isLeftSide(widget.position))
                _betIndicator(betStyle),
              ...List.generate(2, (index) {
                final card = index < _cards.length ? _cards[index] : null;
                final isRed = card?.suit == '♥' || card?.suit == '♦';

                Widget cardWidget = GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.isHero
                      ? () async {
                          final disabled = Set<String>.from(widget.usedCards);
                          if (card != null) disabled.remove('${card.rank}${card.suit}');
                          final selected = await showCardSelector(
                            context,
                            disabledCards: disabled,
                          );
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

                if (!_showCards && !_foldController.isAnimating) {
                  return const SizedBox.shrink();
                }

                return SlideTransition(
                  position: _foldOffset,
                  child: FadeTransition(
                    opacity: _foldOpacity,
                    child: cardWidget,
                  ),
                );
              }),
              if (_currentBet > 0 && !_isLeftSide(widget.position))
                _betIndicator(betStyle),
            ],
          ),
        ),
      ),
        if (widget.editMode)
          Padding(
            padding: EdgeInsets.only(top: 4 * widget.scale),
            child: Column(
              children: [
                SizedBox(
                  width: 60 * widget.scale,
                  child: TextField(
                    controller: _stackController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'Stack',
                      hintStyle: TextStyle(color: Colors.white54),
                      isDense: true,
                    ),
                    onChanged: (v) {
                      final val = int.tryParse(v) ?? 0;
                      widget.player.stack = val;
                      widget.onStackChanged?.call(val);
                      setState(() => _stack = val);
                    },
                  ),
                ),
                SizedBox(height: 4 * widget.scale),
                SizedBox(
                  width: 60 * widget.scale,
                  child: TextField(
                    controller: _betController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'Bet',
                      hintStyle: TextStyle(color: Colors.white54),
                      isDense: true,
                    ),
                    onChanged: (v) {
                      final val = int.tryParse(v) ?? 0;
                      widget.player.bet = val;
                      widget.onBetChanged?.call(val);
                      setState(() => _currentBet = val);
                    },
                  ),
                ),
              ],
            ),
          )
        else
          GestureDetector(
            onLongPress: _editStack,
            child: PlayerStackValue(
              stack: stack ?? 0,
              scale: widget.scale,
              isBust: remaining != null && remaining <= 0,
            ),
          ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          ),
          child: _stackBetAmount != null
              ? Padding(
                  padding: EdgeInsets.only(top: 4 * widget.scale),
                  child: BetSizeLabel(
                    key: ValueKey(_stackBetAmount),
                    amount: _stackBetAmount!,
                    color: _stackBetColor,
                    scale: widget.scale,
                  ),
                )
              : SizedBox(height: 4 * widget.scale),
        ),
        if (widget.showPlayerTypeLabel)
          AnimatedOpacity(
            opacity: widget.showPlayerTypeLabel ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Padding(
              padding: EdgeInsets.only(top: 2.0 * widget.scale),
              child: Text(
                _playerTypeLabel(_playerType),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10 * widget.scale,
                ),
              ),
            ),
          ),
        StackBarWidget(
          stack: stack,
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
        if (_lastActionText != null)
          Positioned(
            top: -8 * widget.scale,
            right: 20 * widget.scale,
            child: AnimatedOpacity(
              opacity: _lastActionOpacity,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 6 * widget.scale, vertical: 2 * widget.scale),
                decoration: BoxDecoration(
                  color: _lastActionColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8 * widget.scale),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _lastActionText!,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12 * widget.scale,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _streetName(widget.street),
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 10 * widget.scale,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (widget.isHero)
          Positioned(
            top: -8 * widget.scale,
            left: -8 * widget.scale,
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 6 * widget.scale, vertical: 2 * widget.scale),
              decoration: BoxDecoration(
                color: Colors.orangeAccent,
                borderRadius: BorderRadius.circular(8 * widget.scale),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orangeAccent.withOpacity(0.6),
                    blurRadius: 6 * widget.scale,
                  ),
                ],
              ),
              child: Text(
                'Hero',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10 * widget.scale,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );

    Widget result = content;

    if (widget.isFolded) {
      result = ClipRect(
        child: ColorFiltered(
          colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
          child: Opacity(opacity: 0.4, child: result),
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

    if (widget.isHero) {
      result = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14 * widget.scale),
          border: Border.all(color: Colors.orangeAccent, width: 2 * widget.scale),
          boxShadow: [
            BoxShadow(
              color: Colors.orangeAccent.withOpacity(0.7),
              blurRadius: 12 * widget.scale,
              spreadRadius: 2 * widget.scale,
            ),
          ],
        ),
        child: result,
      );
    }

    result = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: (_refundGlow && !_winnerHighlight)
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(12 * widget.scale),
              boxShadow: [
                BoxShadow(
                  color: Colors.greenAccent.withOpacity(0.6),
                  blurRadius: 16,
                  spreadRadius: 4,
                ),
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

    result = ScaleTransition(
      scale: _bounceAnimation,
      child: result,
    );

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

  bool _isLeftSide(String? position) {
    switch (position) {
      case 'SB':
      case 'BB':
        return true;
      default:
        return false;
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

  Future<void> _showPlayerTypeMenu(Offset position) async {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect rect = RelativeRect.fromRect(
      Rect.fromPoints(position, position),
      Offset.zero & overlay.size,
    );

    final PlayerType? result = await showMenu<PlayerType>(
      context: context,
      position: rect,
      items: [
        for (final t in PlayerType.values)
          PopupMenuItem<PlayerType>(
            value: t,
            child: Text('${_playerTypeIcon(t)}  ${_playerTypeLabel(t)}'),
          ),
      ],
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

  String _streetName(String street) {
    switch (street) {
      case 'Preflop':
        return 'Префлоп';
      case 'Flop':
        return 'Флоп';
      case 'Turn':
        return 'Тёрн';
      case 'River':
        return 'Ривер';
      default:
        return street;
    }
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

class _BetAmountOverlay extends StatefulWidget {
  final Offset position;
  final int amount;
  final Color color;
  final double scale;
  final VoidCallback? onCompleted;

  const _BetAmountOverlay({
    Key? key,
    required this.position,
    required this.amount,
    required this.color,
    this.scale = 1.0,
    this.onCompleted,
  }) : super(key: key);

  @override
  State<_BetAmountOverlay> createState() => _BetAmountOverlayState();
}

class _ActionLabelOverlay extends StatefulWidget {
  final Offset position;
  final String text;
  final Color color;
  final double scale;
  final VoidCallback? onCompleted;

  const _ActionLabelOverlay({
    Key? key,
    required this.position,
    required this.text,
    required this.color,
    this.scale = 1.0,
    this.onCompleted,
  }) : super(key: key);

  @override
  State<_ActionLabelOverlay> createState() => _ActionLabelOverlayState();
}

class _ActionLabelOverlayState extends State<_ActionLabelOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _offset = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.5)).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        widget.onCompleted?.call();
      }
    });
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        _controller.reverse();
      }
    });
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
      child: SlideTransition(
        position: _offset,
        child: FadeTransition(
          opacity: _opacity,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 8 * widget.scale,
              vertical: 4 * widget.scale,
            ),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8 * widget.scale),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
            ),
            child: Text(
              widget.text,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14 * widget.scale,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BetAmountOverlayState extends State<_BetAmountOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 25,
      ),
      const TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 25,
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
    final double radius = 16 * widget.scale;
    return Positioned(
      left: widget.position.dx - radius,
      top: widget.position.dy - radius,
      child: FadeTransition(
        opacity: _opacity,
        child: Container(
          width: radius * 2,
          height: radius * 2,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(color: Colors.black45, blurRadius: 4),
            ],
          ),
          child: Text(
            '${widget.amount}',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14 * widget.scale,
            ),
          ),
        ),
      ),
    );
  }
}

class _RefundMessageOverlay extends StatefulWidget {
  final Offset position;
  final int amount;
  final double scale;
  final VoidCallback? onCompleted;

  const _RefundMessageOverlay({
    Key? key,
    required this.position,
    required this.amount,
    this.scale = 1.0,
    this.onCompleted,
  }) : super(key: key);

  @override
  State<_RefundMessageOverlay> createState() => _RefundMessageOverlayState();
}

class _RefundMessageOverlayState extends State<_RefundMessageOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

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
        weight: 25,
      ),
      const TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 25,
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
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 8 * widget.scale,
            vertical: 4 * widget.scale,
          ),
          decoration: BoxDecoration(
            color: Colors.lightGreenAccent.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8 * widget.scale),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
          ),
          child: Text(
            '+${widget.amount} returned',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14 * widget.scale,
            ),
          ),
        ),
      ),
    );
  }
}

/// Dark overlay that fades in and out when revealing opponent cards.
class _CardRevealBackdrop extends StatefulWidget {
  final VoidCallback? onCompleted;

  const _CardRevealBackdrop({Key? key, this.onCompleted}) : super(key: key);

  @override
  State<_CardRevealBackdrop> createState() => _CardRevealBackdropState();
}

class _CardRevealBackdropState extends State<_CardRevealBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _controller.forward();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _controller.reverse().whenComplete(() => widget.onCompleted?.call());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: _controller,
            curve: Curves.easeInOut,
          ),
          child: Container(color: Colors.black54),
        ),
      ),
    );
  }
}

/// Highlights the [PlayerZoneWidget] for the given [playerName].
/// This should be called before [showWinPotAnimation] to visually
/// indicate the winner.
void showWinnerHighlight(BuildContext context, String playerName) {
  PotAnimationService().showWinnerHighlight(context, playerName);
}

/// Displays an animated glow overlay around the winning player's zone.
void showWinnerZoneOverlay(BuildContext context, String playerName) {
  final state = playerZoneRegistry[playerName];
  final overlay = Overlay.of(context);
  if (overlay == null || state == null) return;
  final box = state.context.findRenderObject() as RenderBox?;
  if (box == null) return;
  final rect = box.localToGlobal(Offset.zero) & box.size;
  showWinnerZoneHighlightOverlay(
    context: context,
    rect: rect,
    scale: state.widget.scale,
  );
}

/// Updates and reveals cards for the [PlayerZoneWidget] with the given
/// [playerName].
void revealOpponentCards(String playerName, List<CardModel> cards) {
  final state = playerZoneRegistry[playerName];
  state?.updateCards(cards);
}

/// Sets and displays the last action label for the given player.
void setPlayerLastAction(
    String playerName, String text, Color color, String action, [int? amount]) {
  final state = playerZoneRegistry[playerName];
  state?.setLastAction(text, color, action, amount);
}

/// Applies a [outcome] classification to the last action label of [playerName].
void setPlayerLastActionOutcome(String playerName, ActionOutcome outcome) {
  final state = playerZoneRegistry[playerName];
  state?.setLastActionOutcome(outcome);
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
  final state = playerZoneRegistry[playerName];
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
  final state = playerZoneRegistry[playerName];
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
/// Each winner will be highlighted, their cards revealed if provided, and
/// the pot will be moved to them sequentially. Winner celebrations are also
/// shown one after another when [showCelebration] is true.
Future<void> showWinnerSequence(
  BuildContext context,
  List<String> playerNames, {
  Map<String, List<CardModel>>? revealedCardsByPlayer,
  bool showCelebration = true,
}) async {
  final prefs = UserPreferences.instance;
  for (final name in playerNames) {
    // Brief delay before showing the highlight.
    await Future.delayed(const Duration(milliseconds: 500));
    showWinnerHighlight(context, name);

    // Optionally reveal the winner's cards.
    final cards = revealedCardsByPlayer?[name];
    if (cards != null && prefs.showCardReveal) {
      await Future.delayed(const Duration(milliseconds: 500));
      revealOpponentCards(name, cards);
    }

    // Delay slightly longer before moving the pot.
    if (prefs.showPotAnimation) {
      await Future.delayed(const Duration(milliseconds: 700));
      movePotToWinner(context, name);
    }

    if (showCelebration && prefs.showWinnerCelebration) {
      await Future.delayed(const Duration(milliseconds: 1000));
      showWinnerCelebration(context, name);
    }
  }
}

/// Highlights the player at [winnerIndex] and animates their stack increasing
/// by [potAmount] while chips fly from the center pot.
Future<void> triggerWinnerAnimation(int winnerIndex, int potAmount) async {
  _PlayerZoneWidgetState? state;
  for (final s in playerZoneRegistry.values) {
    if (s.widget.playerIndex == winnerIndex) {
      state = s;
      break;
    }
  }
  if (state == null) return;
  final context = state.context;
  final lock = Provider.of<TransitionLockService?>(context, listen: false);
  lock?.lock(const Duration(milliseconds: 1600));
  state.highlightWinner();
  state.playWinChipsAnimation(potAmount);
  await state.animateStackIncrease(potAmount);
  await state.playWinnerBounce();
  lock?.unlock();
}

/// Animates refunds flying from the center pot back to each player in [refunds].
/// Uses the same chip trail as [triggerWinnerAnimation] without highlights.
Future<void> triggerRefundAnimations(Map<int, int> refunds) async {
  await PotAnimationService().triggerRefundAnimations(refunds);
}

