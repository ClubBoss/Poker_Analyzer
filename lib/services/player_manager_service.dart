import 'package:flutter/foundation.dart';

import '../models/action_entry.dart';
import '../models/card_model.dart';
import '../models/player_model.dart';
import 'player_profile_service.dart';

class PlayerManagerService extends ChangeNotifier {
  PlayerManagerService(this.profileService);

  final PlayerProfileService profileService;

  int numberOfPlayers = 6;

  final List<List<CardModel>> playerCards = List.generate(10, (_) => []);
  final List<CardModel> boardCards = [];
  List<PlayerModel> get players => profileService.players;

  int? get opponentIndex => profileService.opponentIndex;
  set opponentIndex(int? v) => profileService.opponentIndex = v;

  Map<int, String> get playerPositions => profileService.playerPositions;
  Map<int, PlayerType> get playerTypes => profileService.playerTypes;
  final Map<int, int> initialStacks = {
    0: 120,
    1: 80,
    2: 100,
    3: 90,
    4: 110,
    5: 70,
    6: 130,
    7: 95,
    8: 105,
    9: 100,
  };

  final List<bool> showActionHints = List.filled(10, true);

  List<String> positionsForPlayers(int count) =>
      profileService.positionsForPlayers(count);

  void setPosition(int playerIndex, String position) {
    profileService.setPosition(playerIndex, position);
  }

  void updatePositions() {
    profileService.updatePositions();
  }

  void onPlayerCountChanged(int value) {
    numberOfPlayers = value;
    profileService.onPlayerCountChanged(value);
  }

  void setHeroIndex(int index) {
    profileService.setHeroIndex(index);
  }

  void setInitialStack(int index, int stack) {
    initialStacks[index] = stack;
    notifyListeners();
  }

  void updatePlayer(
    int index, {
    required int stack,
    required PlayerType type,
    required bool isHero,
    required List<CardModel> cards,
    bool disableCards = false,
  }) {
    initialStacks[index] = stack;
    profileService.playerTypes[index] = type;
    if (isHero) {
      profileService.heroIndex = index;
    } else if (profileService.heroIndex == index) {
      profileService.heroIndex = 0;
    }
    if (!disableCards) {
      playerCards[index] = List<CardModel>.from(cards);
    }
    profileService.updatePositions();
  }

  void selectCard(int index, CardModel card) {
    for (final cards in playerCards) {
      cards.removeWhere((c) => c == card);
    }
    boardCards.removeWhere((c) => c == card);
    _removeFromRevealedCards(card);
    if (playerCards[index].length < 2) {
      playerCards[index].add(card);
    }
    notifyListeners();
  }

  void setPlayerCard(int index, int cardIndex, CardModel card) {
    for (final cards in playerCards) {
      cards.removeWhere((c) => c == card);
    }
    boardCards.removeWhere((c) => c == card);
    _removeFromRevealedCards(card);
    if (playerCards[index].length > cardIndex) {
      playerCards[index][cardIndex] = card;
    } else if (playerCards[index].length == cardIndex) {
      playerCards[index].add(card);
    }
    notifyListeners();
  }

  void setRevealedCard(int playerIndex, int cardIndex, CardModel card) {
    for (final cards in playerCards) {
      cards.removeWhere((c) => c == card);
    }
    boardCards.removeWhere((c) => c == card);
    _removeFromRevealedCards(card);
    final list = players[playerIndex].revealedCards;
    list[cardIndex] = card;
    notifyListeners();
  }

  void selectBoardCard(int index, CardModel card) {
    for (final cards in playerCards) {
      cards.removeWhere((c) => c == card);
    }
    boardCards.removeWhere((c) => c == card);
    _removeFromRevealedCards(card);
    if (index < boardCards.length) {
      boardCards[index] = card;
    } else if (index == boardCards.length) {
      boardCards.add(card);
    }
    notifyListeners();
  }

  void removeBoardCard(int index) {
    if (index < 0 || index >= boardCards.length) return;
    boardCards.removeAt(index);
    notifyListeners();
  }

  void _removeFromRevealedCards(CardModel card) {
    for (final player in players) {
      for (int i = 0; i < player.revealedCards.length; i++) {
        if (player.revealedCards[i] == card) {
          player.revealedCards[i] = null;
        }
      }
    }
  }

  void removePlayer(
    int index, {
      required int heroIndexOverride,
      required List<ActionEntry> actions,
      required List<bool> hintFlags,
  }) {
    if (numberOfPlayers <= 2) return;

    profileService.heroIndex = heroIndexOverride;

    actions.removeWhere((a) => a.playerIndex == index);
    for (int i = 0; i < actions.length; i++) {
      final a = actions[i];
      if (a.playerIndex > index) {
        actions[i] = ActionEntry(
          a.street,
          a.playerIndex - 1,
          a.action,
          amount: a.amount,
          generated: a.generated,
        );
      }
    }

    for (int i = index; i < numberOfPlayers - 1; i++) {
      playerCards[i] = playerCards[i + 1];
      players[i] = players[i + 1];
      initialStacks[i] = initialStacks[i + 1] ?? 0;
      profileService.playerPositions[i] = profileService.playerPositions[i + 1] ?? '';
      profileService.playerTypes[i] = profileService.playerTypes[i + 1] ?? PlayerType.unknown;
      hintFlags[i] = hintFlags[i + 1];
    }
    playerCards[numberOfPlayers - 1] = [];
    players[numberOfPlayers - 1] =
        PlayerModel(name: 'Player $numberOfPlayers');
    initialStacks.remove(numberOfPlayers - 1);
    profileService.actionTagService.shiftAfterPlayerRemoval(index, numberOfPlayers);
    profileService.playerPositions.remove(numberOfPlayers - 1);
    profileService.playerTypes.remove(numberOfPlayers - 1);
    hintFlags[numberOfPlayers - 1] = true;

    if (profileService.heroIndex == index) {
      profileService.heroIndex = 0;
    } else if (profileService.heroIndex > index) {
      profileService.heroIndex--;
    }
    if (profileService.opponentIndex != null) {
      if (profileService.opponentIndex == index) {
        profileService.opponentIndex = null;
      } else if (profileService.opponentIndex! > index) {
        profileService.opponentIndex = profileService.opponentIndex! - 1;
      }
    }

    numberOfPlayers--;
    profileService.updatePositions();
  }

  /// Reset all player-related state to defaults while preserving stack sizes.
  void reset() {
    for (final list in playerCards) {
      list.clear();
    }
    boardCards.clear();
    for (final p in players) {
      p.revealedCards.fillRange(0, p.revealedCards.length, null);
    }
    profileService.opponentIndex = null;
    profileService.playerTypes.clear();
    for (int i = 0; i < showActionHints.length; i++) {
      showActionHints[i] = true;
    }
    notifyListeners();
  }
}

