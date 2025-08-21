import 'package:flutter/material.dart';
import '../models/training_spot.dart';
import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_spot.dart';
import '../widgets/board_cards_widget.dart';
import '../widgets/player_info_widget.dart';
import '../helpers/table_geometry_helper.dart';
import '../widgets/poker_table_painter.dart';
import '../theme/app_colors.dart';

class SpotSolveScreen extends StatefulWidget {
  final TrainingSpot spot;
  final TrainingPackSpot packSpot;
  final TrainingPackTemplate? template;
  const SpotSolveScreen({
    super.key,
    required this.spot,
    required this.packSpot,
    this.template,
  });

  @override
  State<SpotSolveScreen> createState() => _SpotSolveScreenState();
}

class _SpotSolveScreenState extends State<SpotSolveScreen> {
  String? _selected;
  bool? _correct;
  String? _expected;
  String? _hint;
  double? _evDiff;

  void _choose(String action) {
    final isCorrect = action == widget.packSpot.correctAction;
    final heroEv = widget.packSpot.heroEv ?? 0;
    final diffEv = action == 'push' ? heroEv : -heroEv;
    setState(() {
      _selected = action;
      _correct = isCorrect;
      _expected = widget.packSpot.correctAction;
      _hint = widget.packSpot.explanation;
      _evDiff = diffEv;
    });
  }

  Widget _buildTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = TableGeometryHelper.tableScale(
          widget.spot.numberOfPlayers,
        );
        final tableWidth = constraints.maxWidth * 0.9 * scale;
        final tableHeight = tableWidth * 0.55;
        final centerX = constraints.maxWidth / 2;
        final centerY = constraints.maxHeight / 2 - 40;
        final children = <Widget>[
          Positioned(
            left: centerX - tableWidth / 2,
            top: centerY - tableHeight / 2,
            width: tableWidth,
            height: tableHeight,
            child: CustomPaint(painter: PokerTablePainter()),
          ),
          Positioned.fill(
            child: Align(
              alignment: const Alignment(0, -0.1),
              child: BoardCardsWidget(
                currentStreet: 3,
                boardCards: widget.spot.boardCards,
                onCardSelected: (_, __) {},
                onCardLongPress: null,
                usedCards: const {},
                editingDisabled: true,
              ),
            ),
          ),
        ];
        for (int i = 0; i < widget.spot.numberOfPlayers; i++) {
          final pos = TableGeometryHelper.positionForPlayer(
            i,
            widget.spot.numberOfPlayers,
            tableWidth,
            tableHeight,
          );
          final offsetX = centerX + pos.dx - 55 * scale;
          final offsetY = centerY + pos.dy - 55 * scale;
          final cards = widget.spot.playerCards.length > i
              ? widget.spot.playerCards[i]
              : <CardModel>[];
          children.add(
            Positioned(
              left: offsetX,
              top: offsetY,
              child: PlayerInfoWidget(
                position: widget.spot.positions.length > i
                    ? widget.spot.positions[i]
                    : '',
                stack:
                    widget.spot.stacks.length > i ? widget.spot.stacks[i] : 0,
                tag: '',
                cards: cards,
                lastAction: null,
                isActive: false,
                isFolded: false,
                isHero: i == widget.spot.heroIndex,
                isOpponent: false,
                revealCards: true,
                playerTypeIcon: '',
                playerTypeLabel: null,
                positionLabel: null,
                blindLabel: null,
                showLastIndicator: false,
                onTap: null,
                onDoubleTap: null,
                onLongPress: null,
                onEdit: null,
                onStackTap: null,
                onRemove: null,
                onTimeExpired: null,
                onCardTap: null,
                streetInvestment: 0,
                currentBet: 0,
                remainingStack:
                    widget.spot.stacks.length > i ? widget.spot.stacks[i] : 0,
                timersDisabled: true,
                isBust: false,
              ),
            ),
          );
        }
        return SizedBox.expand(child: Stack(children: children));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.template?.name ?? 'Spot')),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(child: _buildTable()),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => _choose('push'),
                      child: const Text('PUSH'),
                    ),
                    ElevatedButton(
                      onPressed: () => _choose('fold'),
                      child: const Text('FOLD'),
                    ),
                  ],
                ),
                if (_selected != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _correct == true ? 'Correct' : 'Incorrect',
                    style: TextStyle(
                      color: _correct == true ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_evDiff != null)
                    Text(
                      '${_evDiff! >= 0 ? '+' : ''}${_evDiff!.toStringAsFixed(1)} BB EV',
                      style: TextStyle(
                        color: _evDiff! >= 0
                            ? Colors.greenAccent
                            : Colors.redAccent,
                      ),
                    ),
                  if (_hint != null && _hint!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _hint!,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  if (widget.spot.userComment != null &&
                      widget.spot.userComment!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        widget.spot.userComment!,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, _correct),
                  child: const Text('Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
