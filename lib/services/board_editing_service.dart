import 'package:flutter/material.dart';

import '../models/card_model.dart';
import '../models/player_model.dart';
import 'board_manager_service.dart';
import 'board_sync_service.dart';
import 'player_manager_service.dart';
import 'player_profile_service.dart';

/// Service that handles validation and warnings for board editing.
class BoardEditingService {
  BoardEditingService({
    required BoardManagerService boardManager,
    required BoardSyncService boardSync,
    required PlayerManagerService playerManager,
    required PlayerProfileService profile,
  })  : _boardManager = boardManager,
        _boardSync = boardSync,
        _playerManager = playerManager,
        _profile = profile;

  final BoardManagerService _boardManager;
  final BoardSyncService _boardSync;
  final PlayerManagerService _playerManager;
  final PlayerProfileService _profile;

  static const List<String> _stageNames = ['Preflop', 'Flop', 'Turn', 'River'];

  List<CardModel> get _boardCards => _boardManager.boardCards;
  List<List<CardModel>> get _playerCards => _playerManager.playerCards;
  List<PlayerModel> get _players => _profile.players;

  int _stageForBoardIndex(int index) {
    if (index <= 2) return 1; // Flop
    if (index == 3) return 2; // Turn
    return 3; // River
  }

  bool _cardsEqual(CardModel? a, CardModel b) =>
      a != null && a.rank == b.rank && a.suit == b.suit;

  bool _isCardInUse(CardModel card) {
    for (final c in _boardCards) {
      if (_cardsEqual(c, card)) return true;
    }
    for (final list in _playerCards) {
      for (final c in list) {
        if (_cardsEqual(c, card)) return true;
      }
    }
    for (final p in _players) {
      for (final c in p.revealedCards) {
        if (_cardsEqual(c, card)) return true;
      }
    }
    return false;
  }

  /// Returns true if [card] is already used elsewhere in the hand.
  bool isDuplicateSelection(CardModel card, CardModel? current) {
    if (_cardsEqual(current, card)) return false;
    return _isCardInUse(card);
  }

  /// Computes a set of card keys currently used across the table.
  Set<String> usedCardKeys({CardModel? except}) {
    String key(CardModel c) => '${c.rank}${c.suit}';
    final keys = <String>{};
    for (final c in _boardCards) {
      keys.add(key(c));
    }
    for (final list in _playerCards) {
      for (final c in list) {
        keys.add(key(c));
      }
    }
    for (final p in _players) {
      for (final c in p.revealedCards) {
        keys.add(key(c));
      }
    }
    if (except != null) keys.remove(key(except));
    return keys;
  }

  /// Display a snackbar warning that the selected card is already in use.
  void showDuplicateCardMessage(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(content: Text('This card is already in use')),
      );
  }

  void _showBoardSkipWarning(
    BuildContext context,
    int prevStage,
    int nextStage,
  ) {
    final prevName = _stageNames[prevStage];
    final nextName = _stageNames[nextStage];
    final count = BoardSyncService.stageCardCounts[prevStage];
    final cardWord = count == 1 ? 'card' : 'cards';
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Please complete the $prevName by adding $count $cardWord before editing the $nextName.',
          ),
        ),
      );
  }

  /// Validate editing the board at [index].
  /// Prevents skipping streets by ensuring previous stages are complete.
  /// Shows a warning message if the user attempts to add cards out of order.
  bool isBoardEditAllowed(BuildContext context, int index) {
    final stage = _stageForBoardIndex(index);
    if (index > _boardCards.length) {
      final expectedStage = _stageForBoardIndex(_boardCards.length);
      _showBoardSkipWarning(context, expectedStage, stage);
      return false;
    }
    if (!_boardSync.isBoardStageComplete(stage - 1)) {
      _showBoardSkipWarning(context, stage - 1, stage);
      return false;
    }
    return true;
  }

  bool canEditBoard(BuildContext context, int index) =>
      isBoardEditAllowed(context, index);

  /// Select or add a board card at [index]. Duplicate and stage order checks
  /// are enforced. Returns true if the card was applied.
  bool selectBoardCard(
    BuildContext context,
    int index,
    CardModel card, {
    CardModel? current,
  }) {
    if (!isBoardEditAllowed(context, index)) return false;
    if (isDuplicateSelection(card, current)) {
      showDuplicateCardMessage(context);
      return false;
    }
    _playerManager.selectBoardCard(index, card);
    return true;
  }

  /// Remove the board card at [index] if it exists.
  void removeBoardCard(int index) {
    _playerManager.removeBoardCard(index);
  }
}
