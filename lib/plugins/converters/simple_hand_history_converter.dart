import '../converter_format_capabilities.dart';
import '../converter_plugin.dart';
import 'package:poker_analyzer/models/saved_hand.dart';
import 'package:poker_analyzer/models/card_model.dart';
import 'package:poker_analyzer/models/action_entry.dart';
import 'package:poker_analyzer/models/player_model.dart';

/// Converter for a very simple hand history text format.
class SimpleHandHistoryConverter extends ConverterPlugin {
  SimpleHandHistoryConverter()
      : super(
          formatId: 'simple_hand_history',
          description: 'Basic hand history text format',
          capabilities: const ConverterFormatCapabilities(
            supportsImport: true,
            supportsExport: false,
            requiresBoard: false,
            supportsMultiStreet: false,
          ),
        );

  @override
  SavedHand? convertFrom(String externalData) {
    final lines = externalData.split(RegExp(r'\r?\n'));
    if (lines.length < 4) return null;
    final handId = lines[0].trim();
    final tableName = lines[1].trim();
    final playerCount = int.tryParse(lines[2].trim());
    if (playerCount == null || playerCount <= 0) return null;

    final cardTokens = lines[3].trim().split(RegExp(r'\s+'));
    final boardCards = <CardModel>[];
    for (final token in cardTokens) {
      if (token.length < 2) continue;
      final rank = token.substring(0, token.length - 1).toUpperCase();
      final suitChar = token[token.length - 1].toLowerCase();
      String suit;
      switch (suitChar) {
        case 'h':
          suit = '♥';
          break;
        case 'd':
          suit = '♦';
          break;
        case 'c':
          suit = '♣';
          break;
        case 's':
          suit = '♠';
          break;
        default:
          continue;
      }
      boardCards.add(CardModel(rank: rank, suit: suit));
    }

    int boardStreet = 0;
    if (boardCards.length >= 5) {
      boardStreet = 3;
    } else if (boardCards.length == 4) {
      boardStreet = 2;
    } else if (boardCards.length >= 3) {
      boardStreet = 1;
    }

    return SavedHand(
      name: handId,
      heroIndex: 0,
      heroPosition: 'BTN',
      numberOfPlayers: playerCount,
      playerCards: List.generate(playerCount, (_) => <CardModel>[]),
      boardCards: boardCards,
      boardStreet: boardStreet,
      actions: <ActionEntry>[],
      stackSizes: {for (var i = 0; i < playerCount; i++) i: 0},
      playerPositions: {for (var i = 0; i < playerCount; i++) i: ''},
      comment: tableName,
      playerTypes: {
        for (var i = 0; i < playerCount; i++) i: PlayerType.unknown
      },
    );
  }
}
