import 'dart:math';
import 'package:flutter/material.dart';
import '../helpers/table_geometry_helper.dart';
import '../helpers/poker_position_helper.dart';
import 'poker_table_painter.dart';
import 'analyzer/player_zone_widget.dart';
import 'position_label.dart';
import 'pot_chip_stack_painter.dart';
import 'dealer_button_indicator.dart';
import 'blind_chip_indicator.dart';

enum TableTheme { green, carbon, blue }

class PokerTableView extends StatefulWidget {
  final int heroIndex;
  final int playerCount;
  final List<String> playerNames;
  final List<double> playerStacks;
  final void Function(int index) onHeroSelected;
  final void Function(int index, double newStack) onStackChanged;
  final void Function(int index, String newName) onNameChanged;
  final double potSize;
  final void Function(double newPot) onPotChanged;
  final double scale;
  final TableTheme theme;
  final void Function(TableTheme)? onThemeChanged;
  const PokerTableView({
    super.key,
    required this.heroIndex,
    required this.playerCount,
    required this.playerNames,
    required this.playerStacks,
    required this.onHeroSelected,
    required this.onStackChanged,
    required this.onNameChanged,
    required this.potSize,
    required this.onPotChanged,
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
        widget.theme != oldWidget.theme) {
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
                child: Padding(
                  padding: EdgeInsets.only(top: 12 * widget.scale),
                  child: Text(
                    'Pot: ${widget.potSize.toStringAsFixed(1)} BB',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
    for (int i = 0; i < widget.playerCount; i++) {
      final seat = TableGeometryHelper.positionForPlayer(i, widget.playerCount, width, height);
      final offset = Offset(width / 2 + seat.dx - 20 * widget.scale, height / 2 + seat.dy - 20 * widget.scale);
      final angle = 2 * pi * i / widget.playerCount + pi / 2;
      final stack = i < widget.playerStacks.length ? widget.playerStacks[i] : 0.0;
      items.add(Positioned(
        left: offset.dx,
        top: offset.dy,
        child: GestureDetector(
          onTap: () => widget.onHeroSelected(i),
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
      items.add(Positioned(
        left: offset.dx,
        top: offset.dy - 18 * widget.scale,
        child: PositionLabel(
          label: positions[i],
          isHero: i == widget.heroIndex,
          scale: widget.scale,
        ),
      ));
      if (positions[i] == 'BTN') {
        final dx = cos(angle) < 0 ? -24 * widget.scale : 24 * widget.scale;
        items.add(Positioned(
          left: offset.dx + dx,
          top: offset.dy - 28 * widget.scale,
          child: DealerButtonIndicator(scale: widget.scale),
        ));
      }
      if (positions[i] == 'SB' || positions[i] == 'BB') {
        final dx = cos(angle) < 0 ? -24 * widget.scale : 24 * widget.scale;
        final color = positions[i] == 'SB' ? Colors.blueAccent : Colors.redAccent;
        items.add(Positioned(
          left: offset.dx + dx,
          top: offset.dy - 28 * widget.scale,
          child: BlindChipIndicator(label: positions[i], color: color, scale: widget.scale),
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
