import 'package:flutter/material.dart';

import '../models/card_model.dart';
import '../services/pot_sync_service.dart';
import 'board_cards_widget.dart';
import 'pot_over_board_widget.dart';
import 'package:provider/provider.dart';

class BoardDisplay extends StatelessWidget {
  final int currentStreet;
  final List<CardModel> boardCards;
  final List<CardModel> revealedBoardCards;
  final PotSyncService potSync;
  final void Function(int, CardModel) onCardSelected;
  final void Function(int index)? onCardLongPress;
  final bool Function(int index)? canEditBoard;
  final Set<String> usedCards;
  final double scale;
  final List<Animation<double>>? revealAnimations;
  final bool editingDisabled;
  final bool showPot;

  const BoardDisplay({
    Key? key,
    required this.currentStreet,
    required this.boardCards,
    required this.revealedBoardCards,
    required this.potSync,
    required this.onCardSelected,
    this.onCardLongPress,
    this.canEditBoard,
    this.usedCards = const {},
    this.scale = 1.0,
    this.revealAnimations,
    this.editingDisabled = false,
    this.showPot = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: potSync,
      child: Stack(
        children: [
          BoardCardsWidget(
            scale: scale,
            currentStreet: currentStreet,
            boardCards: revealedBoardCards,
            revealAnimations: revealAnimations,
            onCardSelected: onCardSelected,
            onCardLongPress: onCardLongPress,
            canEditBoard: canEditBoard,
            usedCards: usedCards,
            editingDisabled: editingDisabled,
          ),
          Consumer<PotSyncService>(
            builder: (_, sync, __) => PotOverBoardWidget(
              potSync: sync,
              currentStreet: currentStreet,
              scale: scale,
              show: showPot,
            ),
          ),
        ],
      ),
    );
  }
}
