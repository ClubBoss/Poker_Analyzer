import '../converter_format_capabilities.dart';
import '../converter_plugin.dart';
import 'package:poker_ai_analyzer/models/saved_hand.dart';
import 'package:poker_ai_analyzer/models/card_model.dart';
import 'package:poker_ai_analyzer/models/action_entry.dart';
import 'package:poker_ai_analyzer/models/player_model.dart';

/// Converter for PokerStars text hand histories.
class PokerStarsHandHistoryConverter extends ConverterPlugin {
  PokerStarsHandHistoryConverter()
      : super(
          formatId: 'pokerstars_hand_history',
          description: 'PokerStars hand history format',
          capabilities: const ConverterFormatCapabilities(
            supportsImport: true,
            supportsExport: false,
            requiresBoard: false,
            supportsMultiStreet: true,
          ),
        );

  @override
  SavedHand? convertFrom(String externalData) {
    final lines = externalData.split(RegExp(r'\r?\n'));
    if (lines.length < 3) return null;

    final headerMatch = RegExp(r'^PokerStars Hand #(\d+)').firstMatch(lines[0]);
    if (headerMatch == null) return null;
    final handId = headerMatch.group(1)!;

    final tableMatch = RegExp(r"^Table '([^']+)'", caseSensitive: false)
        .firstMatch(lines[1]);
    if (tableMatch == null) return null;
    final tableName = tableMatch.group(1)!.trim();

    int playerCount = 0;
    for (var i = 2; i < lines.length; i++) {
      if (lines[i].startsWith('Seat ')) {
        playerCount++;
      } else if (playerCount > 0) {
        break;
      }
    }
    if (playerCount == 0) return null;

    return SavedHand(
      name: handId,
      heroIndex: 0,
      heroPosition: '',
      numberOfPlayers: playerCount,
      playerCards: List.generate(playerCount, (_) => <CardModel>[]),
      boardCards: <CardModel>[],
      boardStreet: 0,
      actions: <ActionEntry>[],
      stackSizes: {for (var i = 0; i < playerCount; i++) i: 0},
      playerPositions: {for (var i = 0; i < playerCount; i++) i: ''},
      playerTypes: {for (var i = 0; i < playerCount; i++) i: PlayerType.unknown},
      comment: tableName,
    );
  }
}
