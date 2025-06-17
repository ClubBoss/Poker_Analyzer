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

    final seatRegex = RegExp(r'^Seat (\d+):\s*(.+?)\s*(?:\(|\$)');
    final seatEntries = <Map<String, dynamic>>[];
    for (var i = 2; i < lines.length; i++) {
      final match = seatRegex.firstMatch(lines[i]);
      if (match != null) {
        seatEntries.add({
          'seat': int.parse(match.group(1)!),
          'name': match.group(2)!.trim(),
        });
      } else if (seatEntries.isNotEmpty) {
        break;
      }
    }

    if (seatEntries.isEmpty) return null;
    seatEntries.sort((a, b) => (a['seat'] as int).compareTo(b['seat'] as int));
    final playerCount = seatEntries.length;

    int heroIndex = 0;
    final playerCards = List.generate(playerCount, (_) => <CardModel>[]);
    String? heroName;
    List<CardModel> heroCards = [];
    CardModel? parseCard(String token) {
      if (token.length < 2) return null;
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
          return null;
      }
      return CardModel(rank: rank, suit: suit);
    }
    final holeIndex = lines.indexWhere((l) => l.startsWith('*** HOLE CARDS ***'));
    if (holeIndex != -1) {
      for (var i = holeIndex + 1; i < lines.length; i++) {
        final dealtMatch = RegExp(r'^Dealt to (.+?) \[(.+?) (.+?)\]')
            .firstMatch(lines[i]);
        if (dealtMatch != null) {
          heroName = dealtMatch.group(1)!.trim();
          final c1 = parseCard(dealtMatch.group(2)!);
          final c2 = parseCard(dealtMatch.group(3)!);
          if (c1 != null && c2 != null) {
            heroCards = [c1, c2];
          }
          break;
        }
      }
    }
    if (heroName != null) {
      heroIndex = seatEntries.indexWhere(
          (e) => (e['name'] as String).toLowerCase() == heroName!.toLowerCase());
      if (heroIndex < 0) heroIndex = 0;
    }
    if (heroCards.isNotEmpty && heroIndex >= 0 && heroIndex < playerCount) {
      playerCards[heroIndex] = heroCards;
    }

    return SavedHand(
      name: handId,
      heroIndex: heroIndex,
      heroPosition: 'BTN',
      numberOfPlayers: playerCount,
      playerCards: playerCards,
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
