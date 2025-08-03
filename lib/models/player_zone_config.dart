import "package:flutter/material.dart";
import "card_model.dart";
import "player_model.dart";

class PlayerZoneConfig {
  final String playerName;
  final String street;
  final String? position;
  final List<CardModel> cards;
  final bool isHero;
  final bool isFolded;
  final bool isShowdownLoser;
  final int currentBet;
  final int? stackSize;
  final Map<int, int>? stackSizes;
  final int? playerIndex;
  final PlayerType playerType;
  final ValueChanged<PlayerType>? onPlayerTypeChanged;
  final bool isActive;
  final bool highlightLastAction;
  final bool showHint;
  final bool showPlayerTypeLabel;
  final int? remainingStack;
  final String? actionTagText;
  final void Function(int, CardModel) onCardsSelected;
  final int maxStackSize;
  final double scale;
  final Set<String> usedCards;
  final bool editMode;
  final PlayerModel player;
  final ValueChanged<int>? onStackChanged;
  final ValueChanged<int>? onBetChanged;
  final ValueChanged<String>? onRevealRequest;

  const PlayerZoneConfig({
    required this.player,
    required this.playerName,
    required this.street,
    this.position,
    required this.cards,
    required this.isHero,
    required this.isFolded,
    this.isShowdownLoser = false,
    this.currentBet = 0,
    this.stackSize,
    this.stackSizes,
    this.playerIndex,
    this.playerType = PlayerType.unknown,
    this.onPlayerTypeChanged,
    required this.onCardsSelected,
    this.isActive = false,
    this.highlightLastAction = false,
    this.showHint = false,
    this.showPlayerTypeLabel = false,
    this.remainingStack,
    this.actionTagText,
    this.maxStackSize = 100,
    this.scale = 1.0,
    this.usedCards = const {},
    this.editMode = false,
    this.onStackChanged,
    this.onBetChanged,
    this.onRevealRequest,
  });
}
