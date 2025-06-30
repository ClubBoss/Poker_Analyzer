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
import '../models/table_state.dart';
import '../services/table_edit_history.dart';
import '../models/card_model.dart';

enum PlayerAction { none, fold, push, call, raise, post }

const playerActionColors = {
  PlayerAction.fold: Colors.grey,
  PlayerAction.push: Colors.orange,
  PlayerAction.call: Colors.blueAccent,
  PlayerAction.raise: Colors.redAccent,
  PlayerAction.post: Colors.grey,
};

enum TableTheme { green, carbon, blue }

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
  final double scale;
  final TableTheme theme;
  final void Function(TableTheme)? onThemeChanged;
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
    this.scale = 1.0,
    this.theme = TableTheme.green,
    this.onThemeChanged,
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
        !listEquals(widget.playerStacks, oldWidget.playerStacks)) {
      setState(() {});
    }
    if (widget.theme != oldWidget.theme) {
      widget.onThemeChanged?.call(widget.theme);
    }
  }

  @override
  Widget build(BuildContext context) {
    final positions = getPositionList(widget.playerCount);
    final width = 220.0 * widget.scale;
    final height = width * 0.55;
    final positiveStacks =
        widget.playerStacks.where((s) => s > 0).toList(growable: false);
    final effectiveStack =
        positiveStacks.isEmpty ? 0.0 : positiveStacks.reduce(min);
    final items = <Widget>[
      Positioned.fill(child: CustomPaint(painter: PokerTablePainter(theme: widget.theme))),
      Positioned.fill(
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 24 * widget.scale,
                height:
                    24 * widget.scale + 3 * 24 * widget.scale * 0.35,
                child: CustomPaint(
                  painter:
                      PotChipStackPainter(chipCount: 4, color: Colors.orange),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final controller =
                      TextEditingController(text: widget.potSize.toString());
                  final result = await showDialog<double>(
                    context: context,
                    builder: (context) => AlertDialog(
                  backgroundColor: Colors.black.withOpacity(0.3),
                  title:
                      const Text('Edit Pot', style: TextStyle(color: Colors.white)),
                  content: TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white10,
                      border:
                          OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
      final seatIndex = (i - widget.heroIndex + widget.playerCount) % widget.playerCount;
      final seat = TableGeometryHelper.positionForPlayer(seatIndex, widget.playerCount, width, height);
      final offset = Offset(width / 2 + seat.dx - 20 * widget.scale, height / 2 + seat.dy - 20 * widget.scale);
      final angle = 2 * pi * seatIndex / widget.playerCount + pi / 2;
      final stack = i < widget.playerStacks.length ? widget.playerStacks[i] : 0.0;
      items.add(Positioned(
        left: offset.dx,
        top: offset.dy,
        child: GestureDetector(
          onTap: () => widget.onHeroSelected(i),
          onDoubleTap: () async {
            final current = widget.playerActions[i];
            final bet = widget.playerBets[i];
            final next =
                PlayerAction.values[(current.index + 1) % PlayerAction.values.length];
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
            } else if (next == PlayerAction.call || next == PlayerAction.raise) {
              final controller = TextEditingController(text: '0');
              final result = await showDialog<double>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.black.withOpacity(0.3),
                  title: Text(next.name.toUpperCase(),
                      style: const TextStyle(color: Colors.white)),
                  content: TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      hintText: 'Enter amount in BB',
                      hintStyle: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel')),
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
            final controller = TextEditingController(text: widget.playerNames[i]);
            final result = await showDialog<String>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Colors.black.withOpacity(0.3),
                title: const Text('Rename Player', style: TextStyle(color: Colors.white)),
                content: TextField(
                  controller: controller,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    hintText: 'Enter name',
                    hintStyle: const TextStyle(color: Colors.white70),
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('OK')),
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
              key: ValueKey('avatar_${widget.playerNames[i]}_${i == widget.heroIndex}'),
              name: widget.playerNames[i],
              isHero: i == widget.heroIndex,
            ),
          ),
        ),
      ));
      final action = i < widget.playerActions.length
          ? widget.playerActions[i]
          : PlayerAction.none;
      final bet = i < widget.playerBets.length ? widget.playerBets[i] : 0.0;
      if (action != PlayerAction.none) {
        items.add(Positioned(
          left: offset.dx + 30 * widget.scale,
          top: offset.dy - 4 * widget.scale,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10 * widget.scale,
                height: 10 * widget.scale,
                decoration: BoxDecoration(
                  color: playerActionColors[action],
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  action.name[0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 6 * widget.scale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (bet > 0)
                Padding(
                  padding: EdgeInsets.only(top: 2 * widget.scale),
                  child: Text(
                    bet.toStringAsFixed(1),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 6 * widget.scale,
                    ),
                  ),
                ),
            ],
          ),
        ));
      }
      items.add(Positioned(
        left: offset.dx,
        top: offset.dy - 18 * widget.scale,
        child: PositionLabel(
          label: positions[seatIndex],
          isHero: i == widget.heroIndex,
          scale: widget.scale,
        ),
      ));
      if (positions[seatIndex] == 'BTN') {
        final dx = cos(angle) < 0 ? -24 * widget.scale : 24 * widget.scale;
        items.add(Positioned(
          left: offset.dx + dx,
          top: offset.dy - 28 * widget.scale,
          child: DealerButtonIndicator(scale: widget.scale),
        ));
      }
      if (positions[seatIndex] == 'SB' || positions[seatIndex] == 'BB') {
        final dx = cos(angle) < 0 ? -24 * widget.scale : 24 * widget.scale;
        final color = positions[seatIndex] == 'SB' ? Colors.blueAccent : Colors.redAccent;
        items.add(Positioned(
          left: offset.dx + dx,
          top: offset.dy - 28 * widget.scale,
          child: BlindChipIndicator(label: positions[seatIndex], color: color, scale: widget.scale),
        ));
      }
      if (i == widget.heroIndex && widget.heroCards.isNotEmpty) {
        final dx = cos(angle) < 0 ? -40 * widget.scale : 40 * widget.scale;
        items.add(Positioned(
          left: offset.dx + dx,
          top: offset.dy - 18 * widget.scale,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: widget.heroCards.take(2).map((c) {
              final isRed = c.suit == '♥' || c.suit == '♦';
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 2 * widget.scale),
                width: 18 * widget.scale,
                height: 26 * widget.scale,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 3,
                      offset: const Offset(1, 2),
                    )
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  '${c.rank}${c.suit}',
                  style: TextStyle(
                    color: isRed ? Colors.red : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12 * widget.scale,
                  ),
                ),
              );
            }).toList(),
          ),
        ));
      }
      items.add(Positioned(
        left: offset.dx,
        top: offset.dy + 42 * widget.scale,
        child: GestureDetector(
          onTap: () async {
            final controller = TextEditingController(text: stack.toString());
            final result = await showDialog<double>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Colors.black.withOpacity(0.3),
                title: const Text('Edit Stack', style: TextStyle(color: Colors.white)),
                content: TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
              fontWeight: i == widget.heroIndex ? FontWeight.bold : FontWeight.normal,
              fontSize: 10 * widget.scale,
            ),
          ),
        ),
      ));
    }
    return SizedBox(width: width, height: height, child: Stack(children: items));
  }
}
