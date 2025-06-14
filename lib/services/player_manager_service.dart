import 'package:flutter/foundation.dart';

import '../helpers/poker_position_helper.dart';
import '../models/action_entry.dart';
import '../models/card_model.dart';
import '../models/player_model.dart';

class PlayerManagerService extends ChangeNotifier {
  int heroIndex = 0;
  String heroPosition = 'BTN';
  int numberOfPlayers = 6;

  final List<List<CardModel>> playerCards = List.generate(10, (_) => []);
  final List<CardModel> boardCards = [];
  final List<PlayerModel> players =
      List.generate(10, (i) => PlayerModel(name: 'Player ${i + 1}'));

  int? opponentIndex;

  Map<int, String> playerPositions = {};
  Map<int, PlayerType> playerTypes = {};
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

  PlayerManagerService() {
    playerPositions = Map.fromIterables(
      List.generate(numberOfPlayers, (i) => i),
      getPositionList(numberOfPlayers),
    );
    playerTypes = Map.fromIterables(
      List.generate(numberOfPlayers, (i) => i),
      List.filled(numberOfPlayers, PlayerType.unknown),
    );
  }

  List<String> positionsForPlayers(int count) => getPositionList(count);

  void setPosition(int playerIndex, String position) {
    playerPositions[playerIndex] = position;
    notifyListeners();
  }

  void updatePositions() {
    final order = positionsForPlayers(numberOfPlayers);
    final heroPosIndex = order.indexOf(heroPosition);
    final buttonIndex = (heroIndex - heroPosIndex + numberOfPlayers) % numberOfPlayers;
    playerPositions = {};
    for (int i = 0; i < numberOfPlayers; i++) {
      final posIndex = (i - buttonIndex + numberOfPlayers) % numberOfPlayers;
      if (posIndex < order.length) {
        playerPositions[i] = order[posIndex];
      }
    }
    notifyListeners();
  }

  void onPlayerCountChanged(int value) {
    numberOfPlayers = value;
    playerPositions = Map.fromIterables(
      List.generate(numberOfPlayers, (i) => i),
      getPositionList(numberOfPlayers),
    );
    for (int i = 0; i < numberOfPlayers; i++) {
      playerTypes.putIfAbsent(i, () => PlayerType.unknown);
    }
    playerTypes.removeWhere((key, _) => key >= numberOfPlayers);
    updatePositions();
  }

  void setHeroIndex(int index) {
    heroIndex = index;
    updatePositions();
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
    playerTypes[index] = type;
    if (isHero) {
      heroIndex = index;
    } else if (heroIndex == index) {
      heroIndex = 0;
    }
    if (!disableCards) {
      playerCards[index] = List<CardModel>.from(cards);
    }
    updatePositions();
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
    required Map<int, String?> actionTags,
    required List<bool> hintFlags,
  }) {
    if (numberOfPlayers <= 2) return;

    heroIndex = heroIndexOverride;

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
      actionTags[i] = actionTags[i + 1];
      playerPositions[i] = playerPositions[i + 1] ?? '';
      playerTypes[i] = playerTypes[i + 1] ?? PlayerType.unknown;
      hintFlags[i] = hintFlags[i + 1];
    }
    playerCards[numberOfPlayers - 1] = [];
    players[numberOfPlayers - 1] =
        PlayerModel(name: 'Player $numberOfPlayers');
    initialStacks.remove(numberOfPlayers - 1);
    actionTags.remove(numberOfPlayers - 1);
    playerPositions.remove(numberOfPlayers - 1);
    playerTypes.remove(numberOfPlayers - 1);
    hintFlags[numberOfPlayers - 1] = true;

    if (heroIndex == index) {
      heroIndex = 0;
    } else if (heroIndex > index) {
      heroIndex--;
    }
    if (opponentIndex != null) {
      if (opponentIndex == index) {
        opponentIndex = null;
      } else if (opponentIndex! > index) {
        opponentIndex = opponentIndex! - 1;
      }
    }

    numberOfPlayers--;
    updatePositions();
  }
}

