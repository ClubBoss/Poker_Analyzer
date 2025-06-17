import '../converter_format_capabilities.dart';
import '../converter_plugin.dart';
import 'package:poker_ai_analyzer/models/saved_hand.dart';
import 'package:poker_ai_analyzer/models/card_model.dart';
import 'package:poker_ai_analyzer/models/action_entry.dart';
import 'package:poker_ai_analyzer/models/player_model.dart';
import 'package:poker_ai_analyzer/helpers/poker_position_helper.dart';

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

  double _parseAmount(String s) =>
      double.tryParse(s.replaceAll(',', '')) ?? 0;

  CardModel? _parseCard(String token) {
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

  List<CardModel> _parseBoardCards(String input) {
    final cardMatches = RegExp(r'\[([^\]]+)\]').allMatches(input).toList();
    final tokens = <String>[];
    if (cardMatches.isEmpty) {
      tokens.addAll(input.split(RegExp(r'\s+')));
    } else {
      for (final m in cardMatches) {
        tokens.addAll(m.group(1)!.split(RegExp(r'\s+')));
      }
    }
    final parsed = <CardModel>[];
    for (final token in tokens) {
      final card = _parseCard(token);
      if (card != null) parsed.add(card);
    }
    return parsed;
  }

  void _parseStreetActions(
    int street,
    List<String> lines,
    int startIndex,
    int endIndex,
    Map<String, int> nameToIndex,
    double? bigBlind,
    List<ActionEntry> actions,
    Map<int, String?> actionTags,
  ) {
    for (int i = startIndex;
        i < lines.length && (endIndex == -1 || i < endIndex);
        i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      Match? m;

      m = RegExp(r'^(.+?): folds', caseSensitive: false).firstMatch(line);
      if (m != null) {
        final idx = nameToIndex[m.group(1)!.toLowerCase()];
        if (idx != null) {
          actions.add(ActionEntry(street, idx, 'fold'));
          actionTags[idx] = 'fold';
        }
        continue;
      }

      m = RegExp(r'^(.+?): calls [\$€£]?([\d,.]+)(.*)',
              caseSensitive: false)
          .firstMatch(line);
      if (m != null) {
        final idx = nameToIndex[m.group(1)!.toLowerCase()];
        if (idx != null) {
          final amt = _parseAmount(m.group(2)!);
          final amount =
              bigBlind != null && bigBlind > 0 ? (amt / bigBlind).round() : amt.round();
          final isAllIn = m.group(3)!.toLowerCase().contains('all-in');
          final action = isAllIn ? 'all-in' : 'call';
          actions.add(ActionEntry(street, idx, action, amount: amount));
          actionTags[idx] = '$action $amount';
        }
        continue;
      }

      m = RegExp(r'^(.+?): raises [\$€£]?([\d,.]+) to [\$€£]?([\d,.]+)(.*)',
              caseSensitive: false)
          .firstMatch(line);
      if (m != null) {
        final idx = nameToIndex[m.group(1)!.toLowerCase()];
        if (idx != null) {
          final amt = _parseAmount(m.group(3)!);
          final amount =
              bigBlind != null && bigBlind > 0 ? (amt / bigBlind).round() : amt.round();
          final isAllIn = m.group(4)!.toLowerCase().contains('all-in');
          final action = isAllIn ? 'all-in' : 'raise';
          actions.add(ActionEntry(street, idx, action, amount: amount));
          actionTags[idx] = '$action $amount';
        }
        continue;
      }
    }
  }

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

    // Determine which seat has the dealer button.
    int? buttonSeat;
    final buttonRegex = RegExp(r'Seat #?(\d+) is the button', caseSensitive: false);
    for (var i = 0; i < lines.length && i < 5; i++) {
      final m = buttonRegex.firstMatch(lines[i]);
      if (m != null) {
        buttonSeat = int.tryParse(m.group(1)!);
        break;
      }
    }

    // Attempt to determine blind amounts from the header or post lines.
    double? bigBlind;
    final blindHeaderMatch =
        RegExp(r'\((?:\$|€|£)?([\d,.]+)/(?:\$|€|£)?([\d,.]+)')
            .firstMatch(lines[0]);
    if (blindHeaderMatch != null) {
      bigBlind = _parseAmount(blindHeaderMatch.group(2)!);
    }
    if (bigBlind == null) {
      for (final line in lines) {
        final bbMatch =
            RegExp(r'posts big blind [\$€£]?([\d,.]+)', caseSensitive: false)
                .firstMatch(line);
        if (bbMatch != null) {
          bigBlind = _parseAmount(bbMatch.group(1)!);
          break;
        }
      }
    }

    final seatRegex =
        RegExp(r'^Seat (\d+):\s*(.+?)\s*\((?:\$|€|£)?([\d,.]+) in chips\)',
            caseSensitive: false);
    final seatEntries = <Map<String, dynamic>>[];
    for (var i = 2; i < lines.length; i++) {
      final match = seatRegex.firstMatch(lines[i]);
      if (match != null) {
        seatEntries.add({
          'seat': int.parse(match.group(1)!),
          'name': match.group(2)!.trim(),
          'stack': _parseAmount(match.group(3)!),
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
    final holeIndex = lines.indexWhere((l) => l.startsWith('*** HOLE CARDS ***'));
    if (holeIndex != -1) {
      for (var i = holeIndex + 1; i < lines.length; i++) {
        final dealtMatch = RegExp(r'^Dealt to (.+?) \[(.+?) (.+?)\]')
            .firstMatch(lines[i]);
        if (dealtMatch != null) {
          heroName = dealtMatch.group(1)!.trim();
          final c1 = _parseCard(dealtMatch.group(2)!);
          final c2 = _parseCard(dealtMatch.group(3)!);
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

    // Parse board streets.
    final boardCards = <CardModel>[];
    int boardStreet = 0;
    final boardLineRegex =
        RegExp(r'^\*\*\*\s+(FLOP|TURN|RIVER)\s+\*\*\*\s+(.*)');
    for (final line in lines) {
      final match = boardLineRegex.firstMatch(line);
      if (match != null) {
        final boardSection = match.group(2)!;
        final parsed = _parseBoardCards(boardSection);
        boardCards
          ..clear()
          ..addAll(parsed);
        if (boardCards.length >= 5) {
          boardStreet = 3;
        } else if (boardCards.length == 4) {
          boardStreet = 2;
        } else if (boardCards.length >= 3) {
          boardStreet = 1;
        } else {
          boardStreet = 0;
        }
      }
    }

    // Phase 22: parse summary section for final board if not already parsed.
    if (boardCards.isEmpty) {
      final summaryIndex =
          lines.indexWhere((l) => l.startsWith('*** SUMMARY'));
      if (summaryIndex != -1) {
        for (var i = summaryIndex + 1; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.startsWith('***')) break;
          final m =
              RegExp(r'^Board \[(.+?)\]', caseSensitive: false).firstMatch(line);
          if (m != null) {
            final parsed = _parseBoardCards(m.group(1)!);
            boardCards
              ..clear()
              ..addAll(parsed);
            if (boardCards.length >= 5) {
              boardStreet = 3;
            } else if (boardCards.length == 4) {
              boardStreet = 2;
            } else if (boardCards.length >= 3) {
              boardStreet = 1;
            } else {
              boardStreet = 0;
            }
            break;
          }
        }
      }
    }

    // Phase 24: parse uncalled bet lines from the summary section.
    final Map<String, double> uncalledReturned = {};
    final summaryIndexForUncalled =
        lines.indexWhere((l) => l.startsWith('*** SUMMARY'));
    if (summaryIndexForUncalled != -1) {
      final uncalledRegex = RegExp(
          r'^Uncalled bet \((?:\$|€|£)?([\d,.]+)\) returned to (.+)',
          caseSensitive: false);
      for (var i = summaryIndexForUncalled + 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.startsWith('***')) break;
        final m = uncalledRegex.firstMatch(line);
        if (m != null) {
          final amount = _parseAmount(m.group(1)!);
          final name = m.group(2)!.trim();
          final key = name.toLowerCase();
          uncalledReturned[key] = (uncalledReturned[key] ?? 0) + amount;
        }
      }
    }

    // Parse preflop actions between HOLE CARDS and FLOP.
    final Map<String, int> nameToIndex = {
      for (int i = 0; i < seatEntries.length; i++)
        (seatEntries[i]['name'] as String).toLowerCase(): i
    };
    final actions = <ActionEntry>[];
    final actionTags = <int, String?>{};
  if (holeIndex != -1) {
    final endIndex =
        lines.indexWhere((l) => l.startsWith('*** FLOP ***'), holeIndex + 1);
    _parseStreetActions(0, lines, holeIndex + 1, endIndex, nameToIndex, bigBlind,
        actions, actionTags);
  }

  // Parse flop actions between FLOP and TURN.
  final flopIndex = lines.indexWhere((l) => l.startsWith('*** FLOP ***'));
  if (flopIndex != -1) {
    final endIndex =
        lines.indexWhere((l) => l.startsWith('*** TURN ***'), flopIndex + 1);
    _parseStreetActions(1, lines, flopIndex + 1, endIndex, nameToIndex, bigBlind,
        actions, actionTags);
  }

  // Parse turn actions between TURN and RIVER.
  final turnIndex =
      lines.indexWhere((l) => l.startsWith('*** TURN'), flopIndex + 1);
  if (turnIndex != -1) {
    final endIndex =
        lines.indexWhere((l) => l.startsWith('*** RIVER'), turnIndex + 1);
    _parseStreetActions(2, lines, turnIndex + 1, endIndex, nameToIndex, bigBlind,
        actions, actionTags);
  }

  // Parse river actions after RIVER line.
  final riverIndex = lines.indexWhere((l) => l.startsWith('*** RIVER'));
  if (riverIndex != -1) {
    final endIndex = lines.indexWhere(
        (l) => l.startsWith('*** SHOW') || l.startsWith('*** SUMMARY'),
        riverIndex + 1);
    _parseStreetActions(3, lines, riverIndex + 1, endIndex, nameToIndex,
        bigBlind, actions, actionTags);
  }

  // Parse showdown section for revealed hole cards.
  final showdownIndex =
      lines.indexWhere((l) => l.startsWith('*** SHOW'));
  if (showdownIndex != -1) {
    final showRegex = RegExp(r'^([^:]+?):\s*shows? \[(.+?)\]',
        caseSensitive: false);
    for (var i = showdownIndex + 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.startsWith('***')) break;
      final m = showRegex.firstMatch(line);
      if (m != null) {
        final name = m.group(1)!.trim();
        final idx = nameToIndex[name.toLowerCase()];
        if (idx != null) {
          if (idx == heroIndex && playerCards[idx].isNotEmpty) {
            continue; // don't overwrite hero cards
          }
          if (playerCards[idx].isEmpty) {
            final tokens = m.group(2)!.split(RegExp(r'\s+'));
            final cards = <CardModel>[];
            for (final t in tokens) {
              final c = _parseCard(t);
              if (c != null) cards.add(c);
            }
            if (cards.length >= 2) {
              playerCards[idx] = cards.sublist(0, 2);
            }
          }
        }
      }
    }
  }

    final stackSizes = <int, int>{};
    for (int i = 0; i < seatEntries.length; i++) {
      final stack = seatEntries[i]['stack'] as double? ?? 0;
      final name = (seatEntries[i]['name'] as String).toLowerCase();
      final returned = uncalledReturned[name] ?? 0;
      final adjustedStack = stack - returned;
      if (bigBlind != null && bigBlind! > 0) {
        stackSizes[i] = (adjustedStack / bigBlind!).round();
      } else {
        stackSizes[i] = adjustedStack.round();
      }
    }

    // Infer player positions based on the button seat and seat order.
    final playerPositions = <int, String>{};
    String heroPosition = 'BTN';
    try {
      final positionOrder = getPositionList(playerCount);
      final btnPosIdx = positionOrder.indexOf('BTN');
      final orderFromBtn = [
        ...positionOrder.sublist(btnPosIdx),
        ...positionOrder.sublist(0, btnPosIdx)
      ];
      int buttonIndex = -1;
      if (buttonSeat != null) {
        buttonIndex =
            seatEntries.indexWhere((e) => e['seat'] == buttonSeat);
      }
      if (buttonIndex < 0) buttonIndex = 0;
      for (int i = 0; i < playerCount; i++) {
        final posIndex = (i - buttonIndex + playerCount) % playerCount;
        playerPositions[i] = orderFromBtn[posIndex];
      }
      heroPosition = playerPositions[heroIndex] ?? heroPosition;
    } catch (_) {
      for (int i = 0; i < playerCount; i++) {
        playerPositions[i] = '';
      }
    }

    return SavedHand(
      name: handId,
      heroIndex: heroIndex,
      heroPosition: heroPosition,
      numberOfPlayers: playerCount,
      playerCards: playerCards,
      boardCards: boardCards,
      boardStreet: boardStreet,
      actions: actions,
      stackSizes: stackSizes,
      playerPositions: playerPositions,
      playerTypes: {for (var i = 0; i < playerCount; i++) i: PlayerType.unknown},
      comment: tableName,
      actionTags: actionTags.isEmpty ? null : actionTags,
    );
  }
}
