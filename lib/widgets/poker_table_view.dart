import 'package:flutter/material.dart';
import '../helpers/table_geometry_helper.dart';
import '../helpers/poker_position_helper.dart';
import 'poker_table_painter.dart';
import 'analyzer/player_zone_widget.dart';

class PokerTableView extends StatefulWidget {
  final int heroIndex;
  final int playerCount;
  final List<String> playerNames;
  final double scale;
  const PokerTableView({
    super.key,
    required this.heroIndex,
    required this.playerCount,
    required this.playerNames,
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
      items.add(Positioned(
        left: offset.dx,
        top: offset.dy,
        child: PlayerAvatar(name: widget.playerNames[i], isHero: i == widget.heroIndex),
      ));
      items.add(Positioned(
        left: offset.dx,
        top: offset.dy - 18 * widget.scale,
        child: Text(
          positions[i],
          style: TextStyle(
            color: i == widget.heroIndex ? Colors.white : Colors.grey,
            fontSize: (i == widget.heroIndex ? 12 : 10) * widget.scale,
            fontWeight: i == widget.heroIndex ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ));
    }
    return SizedBox(width: width, height: height, child: Stack(children: items));
  }
}
