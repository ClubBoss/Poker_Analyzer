import 'package:flutter/material.dart';

import '../models/card_model.dart';
import '../models/action_entry.dart';
import 'board_cards_widget.dart';
import 'pot_over_board_widget.dart';

class BoardDisplay extends StatelessWidget {
  final int currentStreet;
  final List<CardModel> boardCards;
  final List<CardModel> revealedBoardCards;
  final List<ActionEntry> visibleActions;
  final void Function(int, CardModel) onCardSelected;
  final bool Function(int index)? canEditBoard;
  final double scale;

  const BoardDisplay({
    Key? key,
    required this.currentStreet,
    required this.boardCards,
    required this.revealedBoardCards,
    required this.visibleActions,
    required this.onCardSelected,
    this.canEditBoard,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BoardCardsWidget(
          scale: scale,
          currentStreet: currentStreet,
          boardCards: revealedBoardCards,
          onCardSelected: onCardSelected,
          canEditBoard: canEditBoard,
        ),
        PotOverBoardWidget(
          visibleActions: visibleActions,
          currentStreet: currentStreet,
          scale: scale,
        ),
      ],
    );
  }
}
