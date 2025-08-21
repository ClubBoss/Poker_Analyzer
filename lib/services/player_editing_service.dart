import 'package:flutter/material.dart';

import '../models/action_entry.dart';
import '../models/card_model.dart';
import '../models/player_model.dart';
import 'player_manager_service.dart';
import 'stack_manager_service.dart';
import 'playback_manager_service.dart';
import 'player_profile_service.dart';

/// Handles modifications to player info and keeps related services
/// synchronized.
class PlayerEditingService {
  PlayerEditingService({
    required PlayerManagerService playerManager,
    required StackManagerService stackService,
    required PlaybackManagerService playbackManager,
    required PlayerProfileService profile,
  })  : _playerManager = playerManager,
        _stackService = stackService,
        _playbackManager = playbackManager,
        _profile = profile;

  final PlayerManagerService _playerManager;
  final StackManagerService _stackService;
  final PlaybackManagerService _playbackManager;
  final PlayerProfileService _profile;

  List<CardModel> get _boardCards => _playerManager.boardCards;
  List<List<CardModel>> get _playerCards => _playerManager.playerCards;
  List<PlayerModel> get _players => _profile.players;

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

  /// Update position for [playerIndex].
  void setPosition(int playerIndex, String position) {
    _playerManager.setPosition(playerIndex, position);
  }

  /// Change the hero seat to [index].
  void setHeroIndex(int index) {
    _playerManager.setHeroIndex(index);
    _playbackManager.updatePlaybackState();
  }

  /// Update the player count and reset stacks accordingly.
  void onPlayerCountChanged(int count) {
    _playerManager.onPlayerCountChanged(count);
    _stackService.reset(Map<int, int>.from(_playerManager.initialStacks));
    _playbackManager.updatePlaybackState();
  }

  /// Update the initial stack for [index].
  void setInitialStack(int index, int stack) {
    _playerManager.setInitialStack(index, stack);
    _stackService.setInitialStack(index, stack);
    _playbackManager.updatePlaybackState();
  }

  /// Apply [stack], [type], [isHero] and hole [cards] to a player.
  void updatePlayer(
    int index, {
    required int stack,
    required PlayerType type,
    required bool isHero,
    required List<CardModel> cards,
    bool disableCards = false,
  }) {
    _playerManager.updatePlayer(
      index,
      stack: stack,
      type: type,
      isHero: isHero,
      cards: cards,
      disableCards: disableCards,
    );
    _stackService.reset(Map<int, int>.from(_playerManager.initialStacks));
    _playbackManager.updatePlaybackState();
  }

  /// Remove player at [index] and keep stacks/playback in sync.
  void removePlayer(
    int index, {
    required int heroIndexOverride,
    required List<ActionEntry> actions,
    required List<bool> hintFlags,
  }) {
    _playerManager.removePlayer(
      index,
      heroIndexOverride: heroIndexOverride,
      actions: actions,
      hintFlags: hintFlags,
    );
    if (_playbackManager.playbackIndex > actions.length) {
      _playbackManager.seek(actions.length);
    }
    _stackService.reset(Map<int, int>.from(_playerManager.initialStacks));
    _playbackManager.updatePlaybackState();
  }

  /// Select a new card for a player by index. Returns true if the card was
  /// applied, otherwise shows a duplicate warning and returns false.
  bool selectCard(BuildContext context, int playerIndex, CardModel card) {
    if (isDuplicateSelection(card, null)) {
      showDuplicateCardMessage(context);
      return false;
    }
    _playerManager.selectCard(playerIndex, card);
    return true;
  }

  /// Replace the card at [cardIndex] for the player at [playerIndex].
  /// [current] should be the existing card at that position if any.
  /// Returns true if the replacement succeeded.
  bool setPlayerCard(
    BuildContext context,
    int playerIndex,
    int cardIndex,
    CardModel card,
    CardModel? current,
  ) {
    if (isDuplicateSelection(card, current)) {
      showDuplicateCardMessage(context);
      return false;
    }
    _playerManager.setPlayerCard(playerIndex, cardIndex, card);
    return true;
  }

  /// Replace a revealed card for [playerIndex]. Similar duplicate protection
  /// as [setPlayerCard].
  bool setRevealedCard(
    BuildContext context,
    int playerIndex,
    int cardIndex,
    CardModel card,
    CardModel? current,
  ) {
    if (isDuplicateSelection(card, current)) {
      showDuplicateCardMessage(context);
      return false;
    }
    _playerManager.setRevealedCard(playerIndex, cardIndex, card);
    return true;
  }
}
