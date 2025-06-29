import 'package:flutter/material.dart';
import '../helpers/table_geometry_helper.dart';
import '../helpers/poker_position_helper.dart';
import 'poker_table_painter.dart';
import 'analyzer/player_zone_widget.dart';

class PokerTableView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final positions = getPositionList(playerCount);
    final width = 220.0 * scale;
    final height = width * 0.55;
    final items = <Widget>[
      Positioned.fill(child: CustomPaint(painter: PokerTablePainter())),
    ];
    for (int i = 0; i < playerCount; i++) {
      final seat = TableGeometryHelper.positionForPlayer(i, playerCount, width, height);
      final offset = Offset(width / 2 + seat.dx - 20 * scale, height / 2 + seat.dy - 20 * scale);
      items.add(Positioned(
        left: offset.dx,
        top: offset.dy,
        child: PlayerAvatar(name: playerNames[i], isHero: i == heroIndex),
      ));
      if (i == heroIndex) {
        items.add(Positioned(
          left: offset.dx,
          top: offset.dy - 18 * scale,
          child: Text(
            positions[i],
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ));
      }
    }
    return SizedBox(width: width, height: height, child: Stack(children: items));
  }
}
