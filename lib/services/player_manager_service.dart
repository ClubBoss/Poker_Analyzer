import 'package:flutter/material.dart';

import '../models/action_entry.dart';
import '../models/card_model.dart';
import '../models/player_model.dart';
import '../models/saved_hand.dart';
import 'player_profile_service.dart';
import 'player_profile_import_export_service.dart';
import 'stack_manager_service.dart';

class PlayerManagerService extends ChangeNotifier {
  PlayerManagerService(this.profileService)
      : profileImportExportService =
            PlayerProfileImportExportService(profileService);

  final PlayerProfileService profileService;
  final PlayerProfileImportExportService profileImportExportService;

  int get heroIndex => profileService.heroIndex;
  String get heroPosition => profileService.heroPosition;
  set heroPosition(String v) {
    profileService.heroPosition = v;
    profileService.updatePositions();
  }

  int numberOfPlayers = 6;

  final List<List<CardModel>> playerCards = List.generate(10, (_) => []);
  final List<CardModel> boardCards = [];
  List<PlayerModel> get players => profileService.players;

  int? get opponentIndex => profileService.opponentIndex;
  set opponentIndex(int? v) => profileService.opponentIndex = v;

  Map<int, String> get playerPositions => profileService.playerPositions;
  Map<int, PlayerType> get playerTypes => profileService.playerTypes;
  Map<int, String> get playerNotes => profileService.playerNotes;
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

  StackManagerService? _stackService;

  void attachStackManager(StackManagerService service) {
    _stackService = service;
  }

  int getStack(int playerIndex) {
    return _stackService?.getStackForPlayer(playerIndex) ??
        initialStacks[playerIndex] ??
        0;
  }

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

  /// Convert the player profile to a map via [PlayerProfileImportExportService].
  Map<String, dynamic> profileToMap() => profileImportExportService.toMap();

  /// Load player profile information from a serialized map.
  void loadProfileFromMap(Map<String, dynamic> data) {
    profileImportExportService.loadFromMap(data);
    notifyListeners();
  }

  /// Serialize the current player profile to a json string.
  String serializeProfile() => profileImportExportService.serialize();

  /// Deserialize the given json string into the player profile.
  bool deserializeProfile(String jsonStr) {
    final result = profileImportExportService.deserialize(jsonStr);
    if (result) notifyListeners();
    return result;
  }

  Future<void> exportProfileToClipboard(BuildContext context) async {
    await profileImportExportService.exportToClipboard(context);
  }

  Future<void> importProfileFromClipboard(BuildContext context) async {
    await profileImportExportService.importFromClipboard(context);
    notifyListeners();
  }

  Future<void> exportProfileToFile(BuildContext context) async {
    await profileImportExportService.exportToFile(context);
  }

  Future<void> importProfileFromFile(BuildContext context) async {
    await profileImportExportService.importFromFile(context);
    notifyListeners();
  }

  Future<void> exportProfileArchive(BuildContext context) async {
    await profileImportExportService.exportArchive(context);
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

  void setPlayerType(int index, PlayerType type) {
    profileService.setPlayerType(index, type);
    notifyListeners();
  }

  void setPlayerNote(int index, String? note) {
    profileService.setPlayerNote(index, note);
    notifyListeners();
  }

  void resetPlayerProfile(int index) {
    profileService.resetPlayerProfile(index);
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

  /// Load player-related info from a training spot map.
  void loadFromMap(Map<String, dynamic> data) {
    final pcData = data['playerCards'] as List? ?? [];
    final newCards = List.generate(playerCards.length, (_) => <CardModel>[]);
    for (var i = 0; i < pcData.length && i < playerCards.length; i++) {
      final list = pcData[i];
      if (list is List) {
        for (var j = 0; j < list.length && j < 2; j++) {
          final cardMap = list[j];
          if (cardMap is Map) {
            newCards[i].add(CardModel(
              rank: cardMap['rank'] as String,
              suit: cardMap['suit'] as String,
            ));
          }
        }
      }
    }

    final newHeroIndex = data['heroIndex'] as int? ?? 0;
    final newPlayerCount = data['numberOfPlayers'] as int? ?? pcData.length;

    final posList = (data['positions'] as List?)?.cast<String>() ?? [];
    final heroPos = newHeroIndex < posList.length
        ? posList[newHeroIndex]
        : profileService.heroPosition;
    final newPositions = <int, String>{};
    for (var i = 0; i < posList.length; i++) {
      newPositions[i] = posList[i];
    }

    onPlayerCountChanged(newPlayerCount);
    setHeroIndex(newHeroIndex);
    profileService.heroPosition = heroPos;

    for (final list in playerCards) {
      list.clear();
    }
    for (var i = 0; i < newCards.length; i++) {
      playerCards[i].addAll(newCards[i]);
    }

    profileService.playerPositions
      ..clear()
      ..addAll(newPositions);
    profileService.updatePositions();
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
      profileService.playerPositions[i] =
          profileService.playerPositions[i + 1] ?? '';
      profileService.playerTypes[i] =
          profileService.playerTypes[i + 1] ?? PlayerType.unknown;
      hintFlags[i] = hintFlags[i + 1];
    }
    playerCards[numberOfPlayers - 1] = [];
    players[numberOfPlayers - 1] = PlayerModel(name: 'Player $numberOfPlayers');
    initialStacks.remove(numberOfPlayers - 1);
    profileService.actionTagService
        .shiftAfterPlayerRemoval(index, numberOfPlayers);
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

  /// Restore all player-related state from a saved hand.
  void restoreFromHand(SavedHand hand) {
    onPlayerCountChanged(hand.numberOfPlayers);
    setHeroIndex(hand.heroIndex);
    heroPosition = hand.heroPosition;
    for (int i = 0; i < playerCards.length; i++) {
      playerCards[i]
        ..clear()
        ..addAll(i < hand.playerCards.length ? hand.playerCards[i] : []);
    }
    for (int i = 0; i < players.length; i++) {
      final list = players[i].revealedCards;
      list.fillRange(0, list.length, null);
      if (i < hand.revealedCards.length) {
        final from = hand.revealedCards[i];
        for (int j = 0; j < list.length && j < from.length; j++) {
          list[j] = from[j];
        }
      }
    }
    opponentIndex = hand.opponentIndex;
    initialStacks
      ..clear()
      ..addAll(hand.stackSizes);
    profileService.playerPositions
      ..clear()
      ..addAll(hand.playerPositions);
    profileService.playerTypes
      ..clear()
      ..addAll(hand.playerTypes ??
          {for (final k in hand.playerPositions.keys) k: PlayerType.unknown});
    profileService.updatePositions();
    notifyListeners();
  }
}
