
import 'package:flutter/material.dart';

import '../helpers/table_geometry_helper.dart';
import '../models/training_spot.dart';
import 'player_info_overlay.dart';
import 'hero_range_grid_widget.dart';

/// Displays players around a circular table with a highlight for the hero.
///
/// Each seat shows the player index, stack size and last action.
class TrainingSpotDiagram extends StatelessWidget {
  final TrainingSpot spot;
  final double size;

  const TrainingSpotDiagram({super.key, required this.spot, this.size = 200});

  Color _actionColor(String action) {
    if (action.isEmpty) return Colors.white;
    final type = action.split(' ').first.toUpperCase();
    switch (type) {
      case 'PUSH':
        return Colors.green;
      case 'FOLD':
        return Colors.red;
      case 'CALL':
        return Colors.blue;
      case 'RAISE':
        return Colors.yellow;
      default:
        return Colors.white;
    }
  }

  List<String> _lastActions() {
    final actions = List.filled(spot.numberOfPlayers, '');
    for (final a in spot.actions) {
      if (a.playerIndex >= 0 && a.playerIndex < spot.numberOfPlayers) {
        final lab = a.action == 'custom' ? (a.customLabel ?? 'custom') : a.action;
        final label = a.amount != null ? '${lab.toUpperCase()} ${a.amount}' : lab.toUpperCase();
        actions[a.playerIndex] = label;
      }
    }
    return actions;
  }

  @override
  Widget build(BuildContext context) {
    final actions = _lastActions();
    return SizedBox(
      width: size,
      height: size,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableSize = Size(constraints.maxWidth, constraints.maxHeight);
          final center = Offset(tableSize.width / 2, tableSize.height / 2);
          const seatSize = 60.0;
          final seatWidgets = <Widget>[];

          for (int i = 0; i < spot.numberOfPlayers; i++) {
          final seatIndex = (i - spot.heroIndex + spot.numberOfPlayers) % spot.numberOfPlayers;
          final pos = TableGeometryHelper.positionForPlayer(
            seatIndex,
            spot.numberOfPlayers,
            tableSize.width,
            tableSize.height,
          );
          final offset = Offset(center.dx + pos.dx, center.dy + pos.dy);
          final isHero = i == spot.heroIndex;
          final highlightColor = Theme.of(context).colorScheme.secondary;
          final stack = i < spot.stacks.length ? spot.stacks[i] : 0;
          final action = actions[i];

            String? advice;
            if (spot.strategyAdvice != null && i < spot.strategyAdvice!.length) {
              advice = spot.strategyAdvice![i];
            }

            seatWidgets.add(
              Positioned(
                left: offset.dx - seatSize / 2,
                top: offset.dy - seatSize / 2,
                child: GestureDetector(
                  onTapDown: (details) {
                    if (isHero) {
                      if (spot.rangeMatrix != null) {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.grey[900],
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16)),
                          ),
                          builder: (_) => Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: HeroRangeGridWidget(
                              rangeMatrix: spot.rangeMatrix!,
                            ),
                          ),
                        );
                      }
                    } else {
                      final pos =
                          details.globalPosition + const Offset(0, -30);
                      final positionName = i < spot.positions.length
                          ? spot.positions[i]
                          : '';
                      double? equity;
                      if (spot.equities != null && i < spot.equities!.length) {
                        equity = spot.equities![i].toDouble();
                      }
                      showPlayerInfoOverlay(
                        context: context,
                        position: pos,
                        stack: stack,
                        positionName: positionName,
                        equity: equity,
                        advice: advice,
                      );
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                      width: seatSize,
                      height: seatSize,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isHero ? highlightColor : Colors.white30,
                          width: isHero ? 3 : 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isHero
                                ? highlightColor.withValues(alpha: 0.7)
                                : Colors.black54,
                            blurRadius: isHero ? 10 : 2,
                            spreadRadius: isHero ? 3 : 0,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'P${i + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '$stack',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                          if (!isHero && spot.equities != null &&
                              i < spot.equities!.length)
                            Text(
                              'EQ: ${spot.equities![i].round()}%',
                              style: const TextStyle(color: Colors.grey, fontSize: 10),
                            ),
                          if (action.isNotEmpty)
                            Text(
                              action,
                              style: TextStyle(color: _actionColor(action), fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                        ],
                      ),
                    ),
                    if (isHero && advice != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          advice.toUpperCase(),
                          style: TextStyle(
                            color: _actionColor(advice),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }

          return Stack(children: seatWidgets);
        },
      ),
    );
  }
}
