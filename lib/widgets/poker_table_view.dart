import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../helpers/table_geometry_helper.dart';
import '../helpers/poker_position_helper.dart';
import 'poker_table_painter.dart';
import 'analyzer/player_zone_widget.dart';
import 'position_label.dart';
import 'pot_chip_stack_painter.dart';
import 'dealer_button_indicator.dart';
import 'blind_chip_indicator.dart';
import 'board_cards_widget.dart';
import '../models/table_state.dart';
import '../services/table_edit_history.dart';
import '../models/card_model.dart';
import 'playing_card_widget.dart';
import 'side_pot_badges.dart';

enum PlayerAction { none, fold, push, call, raise, post }

const playerActionColors = {
  PlayerAction.fold: Colors.grey,
  PlayerAction.push: Colors.orange,
  PlayerAction.call: Colors.blueAccent,
  PlayerAction.raise: Colors.redAccent,
  PlayerAction.post: Colors.brown,
};

enum TableTheme { green, carbon, blue, dark }

class PokerTableView extends StatefulWidget {
  final int heroIndex;
  final int playerCount;
  final List<String> playerNames;
  final List<double> playerStacks;
  final List<PlayerAction> playerActions;
  final List<double> playerBets;
  final void Function(int index) onHeroSelected;
  final void Function(int index, double newStack) onStackChanged;
  final void Function(int index, String newName) onNameChanged;
  final void Function(int index, double bet) onBetChanged;
  final void Function(int index, PlayerAction action) onActionChanged;
  final double potSize;
  final void Function(double newPot) onPotChanged;
  final List<CardModel> heroCards;
  final List<List<CardModel>> revealedCards;
  final List<CardModel> boardCards;
  final List<List<CardModel>> multiBoardCards;
  final int currentStreet;
  final String? actionSeatId;
  final bool highlightHeroAction;
  final double scale;
  final double sizeFactor;
  final TableTheme theme;
  final void Function(TableTheme)? onThemeChanged;
  final bool compactMode;
  final bool showStackValues;
  final bool showRevealedCards;
  final bool showPlayerActions;
  final bool showBoardLabels;
  final List<int>? sidePotsChips;
  final double bbChips;
  const PokerTableView({
    super.key,
    required this.heroIndex,
    required this.playerCount,
    required this.playerNames,
    required this.playerStacks,
    required this.playerActions,
    required this.playerBets,
    required this.onHeroSelected,
    required this.onStackChanged,
    required this.onNameChanged,
    required this.onBetChanged,
    required this.onActionChanged,
    required this.potSize,
    required this.onPotChanged,
    this.heroCards = const [],
    this.revealedCards = const [],
    this.boardCards = const [],
    this.multiBoardCards = const [],
    this.currentStreet = 0,
    this.actionSeatId,
    this.highlightHeroAction = false,
    this.scale = 1.0,
    this.sizeFactor = 1.0,
    this.theme = TableTheme.dark,
    this.onThemeChanged,
    this.compactMode = false,
    this.showStackValues = true,
    this.showRevealedCards = true,
    this.showPlayerActions = true,
    this.showBoardLabels = true,
    this.sidePotsChips,
    this.bbChips = 1.0,
  });

  @override
  State<PokerTableView> createState() => _PokerTableViewState();
}

class _PokerTableViewState extends State<PokerTableView> {
  @override
  void didUpdateWidget(covariant PokerTableView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.heroIndex != oldWidget.heroIndex ||
        widget.theme != oldWidget.theme ||
        widget.potSize != oldWidget.potSize ||
        !listEquals(widget.playerStacks, oldWidget.playerStacks) ||
        !listEquals(widget.sidePotsChips, oldWidget.sidePotsChips) ||
        widget.bbChips != oldWidget.bbChips) {
      setState(() {});
    }
    if (widget.theme != oldWidget.theme) {
      widget.onThemeChanged?.call(widget.theme);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final positions = getPositionList(widget.playerCount);
        double width =
            (constraints.maxWidth.isFinite ? constraints.maxWidth : 220.0) *
                widget.sizeFactor;
        double height = width * 0.55;
        if (constraints.maxHeight.isFinite && height > constraints.maxHeight) {
          height = constraints.maxHeight;
          width = height / 0.55;
        }
        final positiveStacks =
            widget.playerStacks.where((s) => s > 0).toList(growable: false);
        final effectiveStack =
            positiveStacks.isEmpty ? 0.0 : positiveStacks.reduce(min);
        int? actionSeatIndex;
        if (widget.actionSeatId != null) {
          actionSeatIndex = int.tryParse(widget.actionSeatId!);
        } else if (widget.highlightHeroAction) {
          actionSeatIndex = widget.heroIndex;
        }
        final items = <Widget>[
          Positioned.fill(
            child: CustomPaint(painter: PokerTablePainter(theme: widget.theme)),
          ),
          Positioned.fill(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 24 * widget.scale,
                    height: 24 * widget.scale + 3 * 24 * widget.scale * 0.35,
                    child: CustomPaint(
                      painter: PotChipStackPainter(
                        chipCount: 4,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                  _buildBoards(),
                  if ((widget.sidePotsChips ?? const []).isNotEmpty)
                    Align(
                      alignment: const Alignment(0, -0.05),
                      child: SidePotBadges(
                        sidePotsChips: widget.sidePotsChips!,
                        bb: widget.bbChips <= 0 ? 1.0 : widget.bbChips,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  GestureDetector(
                    onTap: () async {
                      final controller = TextEditingController(
                        text: widget.potSize.toString(),
                      );
                      final result = await showDialog<double>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: Colors.black.withValues(alpha: 0.3),
                          title: const Text(
                            'Edit Pot',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: TextField(
                            controller: controller,
                            autofocus: true,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white10,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              hintText: 'Enter pot in BB',
                              hintStyle: const TextStyle(color: Colors.white70),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                final value = double.tryParse(controller.text);
                                Navigator.pop(context, value);
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                      if (result != null) {
                        widget.onPotChanged(result);
                        setState(() {});
                      }
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 12 * widget.scale),
                          child: Text(
                            'Pot: ${widget.potSize.toStringAsFixed(1)} BB',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 2 * widget.scale),
                          child: Text(
                            'Eff: ${effectiveStack.toStringAsFixed(1)} BB | SPR: ${(effectiveStack / max(widget.potSize, 0.1)).toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 8 * widget.scale,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ];
        for (int i = 0; i < widget.playerCount; i++) {
          final seatIndex =
              (i - widget.heroIndex + widget.playerCount) % widget.playerCount;
          final seat = TableGeometryHelper.positionForPlayer(
            seatIndex,
            widget.playerCount,
            width,
            height,
          );
          final offset = Offset(
            width / 2 + seat.dx - 20 * widget.scale,
            height / 2 + seat.dy - 20 * widget.scale,
          );
          final angle = 2 * pi * seatIndex / widget.playerCount + pi / 2;
          final stack =
              i < widget.playerStacks.length ? widget.playerStacks[i] : 0.0;
          if (actionSeatIndex != null && i == actionSeatIndex) {
            final radius = 24 * widget.scale;
            items.add(
              Positioned(
                left: offset.dx - radius,
                top: offset.dy - radius,
                child: _ActionSpotHighlight(scale: widget.scale),
              ),
            );
          }
          items.add(
            Positioned(
              left: offset.dx,
              top: offset.dy,
              child: GestureDetector(
                onTap: () => widget.onHeroSelected(i),
                onDoubleTap: () async {
                  final current = widget.playerActions[i];
                  final bet = widget.playerBets[i];
                  final next = PlayerAction
                      .values[(current.index + 1) % PlayerAction.values.length];
                  double stackValue = widget.playerStacks[i];
                  double potValue = widget.potSize;
                  if (bet > 0) {
                    stackValue += bet;
                    potValue -= bet;
                    widget.onStackChanged(i, stackValue);
                    widget.onPotChanged(potValue);
                    widget.onBetChanged(i, 0);
                  }
                  if (next == PlayerAction.push) {
                    TableEditHistory.instance.push(
                      TableState(
                        playerCount: widget.playerCount,
                        names: List<String>.from(widget.playerNames),
                        stacks: List<double>.from(widget.playerStacks),
                        heroIndex: widget.heroIndex,
                        pot: widget.potSize,
                      ),
                    );
                    potValue += stackValue;
                    widget.onStackChanged(i, 0);
                    widget.onPotChanged(potValue);
                    widget.onBetChanged(i, stackValue);
                  } else if (next == PlayerAction.call ||
                      next == PlayerAction.raise) {
                    final controller = TextEditingController(text: '0');
                    final result = await showDialog<double>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.black.withValues(alpha: 0.3),
                        title: Text(
                          next.name.toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                        content: TextField(
                          controller: controller,
                          autofocus: true,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white10,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            hintText: 'Enter amount in BB',
                            hintStyle: const TextStyle(color: Colors.white70),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              final value = double.tryParse(controller.text);
                              Navigator.pop(context, value);
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                    if (result == null) return;
                    TableEditHistory.instance.push(
                      TableState(
                        playerCount: widget.playerCount,
                        names: List<String>.from(widget.playerNames),
                        stacks: List<double>.from(widget.playerStacks),
                        heroIndex: widget.heroIndex,
                        pot: widget.potSize,
                      ),
                    );
                    stackValue = stackValue - result;
                    potValue = potValue + result;
                    widget.onStackChanged(i, stackValue);
                    widget.onPotChanged(potValue);
                    widget.onBetChanged(i, result);
                  }
                  widget.onActionChanged(i, next);
                  setState(() {});
                },
                onLongPress: () async {
                  final controller = TextEditingController(
                    text: widget.playerNames[i],
                  );
                  final result = await showDialog<String>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Colors.black.withValues(alpha: 0.3),
                      title: const Text(
                        'Rename Player',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: TextField(
                        controller: controller,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white10,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          hintText: 'Enter name',
                          hintStyle: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context, controller.text.trim()),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                  if (result != null) {
                    widget.onNameChanged(i, result);
                    setState(() {});
                  }
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  ),
                  child: PlayerAvatar(
                    key: ValueKey(
                      'avatar_${widget.playerNames[i]}_${i == widget.heroIndex}',
                    ),
                    name: widget.playerNames[i],
                    isHero: i == widget.heroIndex,
                  ),
                ),
              ),
            ),
          );
          if (widget.showStackValues) {
            final textColor = stack > 100
                ? Colors.green
                : (stack >= 20 ? Colors.yellow : Colors.red);
            final text = widget.compactMode
                ? stack.toStringAsFixed(0)
                : '${stack.toStringAsFixed(0)} BB';
            final fontSize = (widget.compactMode ? 8 : 10) * widget.scale;
            final dx = widget.compactMode ? 28 * widget.scale : 0.0;
            final dy =
                widget.compactMode ? -4 * widget.scale : -10 * widget.scale;
            items.add(
              Positioned(
                left: offset.dx + dx,
                top: offset.dy + dy,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2 * widget.scale,
                    vertical: 1 * widget.scale,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                    ),
                  ),
                ),
              ),
            );
          }
          final action = i < widget.playerActions.length
              ? widget.playerActions[i]
              : PlayerAction.none;
          final bet = i < widget.playerBets.length ? widget.playerBets[i] : 0.0;
          items.add(
            Positioned(
              left: offset.dx + 30 * widget.scale,
              top: offset.dy - 4 * widget.scale,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: widget.showPlayerActions && action != PlayerAction.none
                    ? _ActionIndicator(
                        action: action,
                        bet: bet,
                        scale: widget.scale,
                      )
                    : SizedBox(
                        width: 10 * widget.scale,
                        height: 10 * widget.scale,
                      ),
              ),
            ),
          );
          items.add(
            Positioned(
              left: offset.dx,
              top: offset.dy - 18 * widget.scale,
              child: PositionLabel(
                label: positions[seatIndex],
                isHero: i == widget.heroIndex,
                scale: widget.scale,
              ),
            ),
          );
          if (positions[seatIndex] == 'BTN') {
            final dx = cos(angle) < 0 ? -24 * widget.scale : 24 * widget.scale;
            items.add(
              Positioned(
                left: offset.dx + dx,
                top: offset.dy - 28 * widget.scale,
                child: DealerButtonIndicator(scale: widget.scale),
              ),
            );
          }
          if (positions[seatIndex] == 'SB' || positions[seatIndex] == 'BB') {
            final dx = cos(angle) < 0 ? -24 * widget.scale : 24 * widget.scale;
            final color = positions[seatIndex] == 'SB'
                ? Colors.blueAccent
                : Colors.redAccent;
            items.add(
              Positioned(
                left: offset.dx + dx,
                top: offset.dy - 28 * widget.scale,
                child: BlindChipIndicator(
                  label: positions[seatIndex],
                  color: color,
                  scale: widget.scale,
                ),
              ),
            );
          }
          List<CardModel> cardsToShow = [];
          if (i == widget.heroIndex && widget.heroCards.isNotEmpty) {
            cardsToShow = widget.heroCards.take(2).toList();
          } else if (widget.showRevealedCards &&
              i < widget.revealedCards.length &&
              widget.revealedCards[i].isNotEmpty) {
            cardsToShow = widget.revealedCards[i].take(2).toList();
          }

          if (cardsToShow.isNotEmpty) {
            final dx = cos(angle) < 0 ? -40 * widget.scale : 40 * widget.scale;
            final keyString =
                cardsToShow.map((c) => '${c.rank}${c.suit}').join('-');
            items.add(
              Positioned(
                left: offset.dx + dx,
                top: offset.dy - 18 * widget.scale,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: Row(
                    key: ValueKey('cards_${i}_$keyString'),
                    mainAxisSize: MainAxisSize.min,
                    children: cardsToShow
                        .map(
                          (c) =>
                              PlayingCardWidget(card: c, scale: widget.scale),
                        )
                        .toList(),
                  ),
                ),
              ),
            );
          }
          items.add(
            Positioned(
              left: offset.dx,
              top: offset.dy + 42 * widget.scale,
              child: GestureDetector(
                onTap: () async {
                  final controller = TextEditingController(
                    text: stack.toString(),
                  );
                  final result = await showDialog<double>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Colors.black.withValues(alpha: 0.3),
                      title: const Text(
                        'Edit Stack',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: TextField(
                        controller: controller,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
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
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            final value = double.tryParse(controller.text);
                            Navigator.pop(context, value);
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                  if (result != null) {
                    widget.onStackChanged(i, result);
                    setState(() {});
                  }
                },
                child: Text(
                  '${stack.toStringAsFixed(1)} BB',
                  style: TextStyle(
                    color: i == widget.heroIndex ? Colors.white : Colors.grey,
                    fontWeight: i == widget.heroIndex
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 10 * widget.scale,
                  ),
                ),
              ),
            ),
          );
        }
        return SizedBox(
          width: width,
          height: height,
          child: Stack(children: items),
        );
      },
    );
  }

  Widget _buildBoards() {
    List<List<CardModel>> boards = widget.multiBoardCards.isNotEmpty
        ? List<List<CardModel>>.from(widget.multiBoardCards)
        : (widget.boardCards.isNotEmpty ? [widget.boardCards] : []);

    if (widget.compactMode && boards.isNotEmpty) {
      boards = [boards.first];
    }

    boards = boards.take(3).toList();

    if (boards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: Align(
        alignment: const Alignment(0, -0.05),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Column(
            key: ValueKey(boards.length),
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < boards.length; i++)
                Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : 12 * widget.scale),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.showBoardLabels && boards.length > 1)
                        Padding(
                          padding: EdgeInsets.only(right: 8 * widget.scale),
                          child: Text(
                            'Board ${i + 1}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10 * widget.scale,
                            ),
                          ),
                        ),
                      BoardCardsWidget(
                        currentStreet: widget.currentStreet,
                        boardCards: boards[i],
                        onCardSelected: (_, __) {},
                        onCardLongPress: null,
                        usedCards: const {},
                        editingDisabled: true,
                        scale: widget.scale,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionIndicator extends StatelessWidget {
  final PlayerAction action;
  final double bet;
  final double scale;
  const _ActionIndicator({
    required this.action,
    required this.bet,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    const labels = {
      PlayerAction.fold: 'F',
      PlayerAction.call: 'C',
      PlayerAction.raise: 'R',
      PlayerAction.push: 'P',
      PlayerAction.post: 'Post',
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 4 * scale,
            vertical: 2 * scale,
          ),
          decoration: BoxDecoration(
            color: playerActionColors[action],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            labels[action] ?? action.name,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 8 * scale,
            ),
          ),
        ),
        if (bet > 0)
          Padding(
            padding: EdgeInsets.only(top: 2 * scale),
            child: Text(
              bet.toStringAsFixed(1),
              style: TextStyle(color: Colors.white, fontSize: 6 * scale),
            ),
          ),
      ],
    );
  }
}

class _ActionSpotHighlight extends StatefulWidget {
  final double scale;
  const _ActionSpotHighlight({required this.scale});

  @override
  State<_ActionSpotHighlight> createState() => _ActionSpotHighlightState();
}

class _ActionSpotHighlightState extends State<_ActionSpotHighlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double radius = 24 * widget.scale;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Transform.scale(scale: _pulse.value, child: child);
      },
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.yellow.withValues(alpha: 0.6),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.yellow.withValues(alpha: 0.4),
              blurRadius: 6 * widget.scale,
              spreadRadius: 2 * widget.scale,
            ),
          ],
        ),
      ),
    );
  }
}
