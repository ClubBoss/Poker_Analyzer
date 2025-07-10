import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../poker_analyzer_screen.dart';

class ActionEditor extends StatelessWidget {
  const ActionEditor({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.read<PokerAnalyzerScreenState>();
    return _HandEditorSection(
      actionHistory: state._actionHistory,
      playerPositions: state.playerPositions,
      heroIndex: state.heroIndex,
      commentController: state._handContext.commentController,
      tagsController: state._handContext.tagsController,
      tournamentIdController: state._handContext.tournamentIdController,
      buyInController: state._handContext.buyInController,
      prizePoolController: state._handContext.totalPrizePoolController,
      entrantsController: state._handContext.numberOfEntrantsController,
      gameTypeController: state._handContext.gameTypeController,
      currentStreet: state.currentStreet,
      pots: state._potSync.pots,
      stackSizes: state._stackService.currentStacks,
      onEdit: state._editAction,
      onDelete: state._deleteAction,
      visibleCount: state._playbackManager.playbackIndex,
      evaluateActionQuality: state._evaluateActionQuality,
      onAnalyze: () {},
    );
  }
}

