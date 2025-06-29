import 'package:flutter/material.dart';
import '../helpers/table_geometry_helper.dart';
import '../helpers/poker_position_helper.dart';
import 'poker_table_painter.dart';
import 'analyzer/player_zone_widget.dart';
import 'position_label.dart';

class PokerTableView extends StatefulWidget {
  final int heroIndex;
  final int playerCount;
  final List<String> playerNames;
  final List<double> playerStacks;
  final void Function(int index) onHeroSelected;
  final void Function(int index, double newStack) onStackChanged;
  final void Function(int index, String newName) onNameChanged;
  final double scale;
  const PokerTableView({
    super.key,
    required this.heroIndex,
    required this.playerCount,
    required this.playerNames,
    required this.playerStacks,
    required this.onHeroSelected,
    required this.onStackChanged,
    required this.onNameChanged,
    this.scale = 1.0,
  });

  @override
  State<PokerTableView> createState() => _PokerTableViewState();
}

class _PokerTableViewState extends State<PokerTableView> {
  @override
  void didUpdateWidget(covariant PokerTableView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.heroIndex != oldWidget.heroIndex) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final positions = getPositionList(widget.playerCount);
    final width = 220.0 * widget.scale;
    final height = width * 0.55;
    final items = <Widget>[
      Positioned.fill(child: CustomPaint(painter: PokerTablePainter())),
    ];
    for (int i = 0; i < widget.playerCount; i++) {
      final seat = TableGeometryHelper.positionForPlayer(i, widget.playerCount, width, height);
      final offset = Offset(width / 2 + seat.dx - 20 * widget.scale, height / 2 + seat.dy - 20 * widget.scale);
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
