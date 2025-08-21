import 'package:flutter/foundation.dart';

import '../helpers/poker_position_helper.dart';
import '../models/card_model.dart';
import '../models/player_model.dart';
import '../models/action_entry.dart';
import 'action_tag_service.dart';

/// Manages player-specific profiles such as positions, types and revealed cards.
class PlayerProfileService extends ChangeNotifier {
  int heroIndex = 0;
  String heroPosition = 'BTN';
  int numberOfPlayers = 6;
  int? opponentIndex;

  Map<int, String> playerPositions = {};
  Map<int, PlayerType> playerTypes = {};
  Map<int, String> playerNotes = {};
  final List<PlayerModel> players = List.generate(
    10,
    (i) => PlayerModel(name: 'Player ${i + 1}'),
  );
  final ActionTagService actionTagService;

  PlayerProfileService({ActionTagService? actionTagService})
      : actionTagService = actionTagService ?? ActionTagService() {
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
    final buttonIndex =
        (heroIndex - heroPosIndex + numberOfPlayers) % numberOfPlayers;
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

  void setRevealedCard(int playerIndex, int cardIndex, CardModel card) {
    final list = players[playerIndex].revealedCards;
    list[cardIndex] = card;
    notifyListeners();
  }

  void setPlayerType(int index, PlayerType type) {
    playerTypes[index] = type;
    notifyListeners();
  }

  void setPlayerNote(int index, String? note) {
    if (note == null || note.trim().isEmpty) {
      playerNotes.remove(index);
    } else {
      playerNotes[index] = note.trim();
    }
    notifyListeners();
  }

  void resetPlayerProfile(int index) {
    playerTypes[index] = PlayerType.unknown;
    playerNotes.remove(index);
    notifyListeners();
  }

  void removePlayer(
    int index, {
    required int heroIndexOverride,
    required List<ActionEntry> actions,
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
      players[i] = players[i + 1];
      playerPositions[i] = playerPositions[i + 1] ?? '';
      playerTypes[i] = playerTypes[i + 1] ?? PlayerType.unknown;
      hintFlags[i] = hintFlags[i + 1];
    }
    players[numberOfPlayers - 1] = PlayerModel(name: 'Player $numberOfPlayers');
    actionTagService.shiftAfterPlayerRemoval(index, numberOfPlayers);
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

  /// Reset all player-related state to defaults while preserving names.
  void reset() {
    for (final p in players) {
      p.revealedCards.fillRange(0, p.revealedCards.length, null);
    }
    opponentIndex = null;
    playerTypes.clear();
    playerNotes.clear();
    actionTagService.clear();
    notifyListeners();
  }
}
