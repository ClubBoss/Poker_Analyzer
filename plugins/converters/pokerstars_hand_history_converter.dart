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

  @override
  SavedHand? convertFrom(String externalData) {
    final lines = externalData.split(RegExp(r'\r?\n'));
    if (lines.length < 3) return null;

    double _parseAmount(String s) =>
        double.tryParse(s.replaceAll(',', '')) ?? 0;

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

    // Parse board streets.
    final boardCards = <CardModel>[];
    int boardStreet = 0;
    final boardLineRegex =
        RegExp(r'^\*\*\*\s+(FLOP|TURN|RIVER)\s+\*\*\*\s+(.*)');
    for (final line in lines) {
      final match = boardLineRegex.firstMatch(line);
      if (match != null) {
        final boardSection = match.group(2)!;
        final cardMatches =
            RegExp(r'\[([^\]]+)\]').allMatches(boardSection).toList();
        final tokens = <String>[];
        for (final m in cardMatches) {
          tokens.addAll(m.group(1)!.split(RegExp(r'\s+')));
        }
        final parsed = <CardModel>[];
        for (final token in tokens) {
          final card = parseCard(token);
          if (card != null) parsed.add(card);
        }
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

    // Parse preflop actions between HOLE CARDS and FLOP.
    final Map<String, int> nameToIndex = {
      for (int i = 0; i < seatEntries.length; i++)
        (seatEntries[i]['name'] as String).toLowerCase(): i
    };
    final actions = <ActionEntry>[];
    final actionTags = <int, String?>{};
    if (holeIndex != -1) {
      final endIndex = lines.indexWhere(
          (l) => l.startsWith('*** FLOP ***'), holeIndex + 1);
      for (int i = holeIndex + 1;
          i < lines.length && (endIndex == -1 || i < endIndex);
          i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        Match? m;

        m = RegExp(r'^(.+?): folds', caseSensitive: false).firstMatch(line);
        if (m != null) {
          final idx = nameToIndex[m.group(1)!.toLowerCase()];
          if (idx != null) {
            actions.add(ActionEntry(0, idx, 'fold'));
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
                bigBlind != null && bigBlind! > 0
                    ? (amt / bigBlind!).round()
                    : amt.round();
            final isAllIn = m.group(3)!.toLowerCase().contains('all-in');
            final action = isAllIn ? 'all-in' : 'call';
            actions.add(ActionEntry(0, idx, action, amount: amount));
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
                bigBlind != null && bigBlind! > 0
                    ? (amt / bigBlind!).round()
                    : amt.round();
            final isAllIn = m.group(4)!.toLowerCase().contains('all-in');
            final action = isAllIn ? 'all-in' : 'raise';
            actions.add(ActionEntry(0, idx, action, amount: amount));
            actionTags[idx] = '$action $amount';
          }
          continue;
        }
      }
    }

    // Parse flop actions between FLOP and TURN.
    final flopIndex =
        lines.indexWhere((l) => l.startsWith('*** FLOP ***'));
    if (flopIndex != -1) {
      final endIndex =
          lines.indexWhere((l) => l.startsWith('*** TURN ***'), flopIndex + 1);
      for (int i = flopIndex + 1;
          i < lines.length && (endIndex == -1 || i < endIndex);
          i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        Match? m;

        m = RegExp(r'^(.+?): folds', caseSensitive: false).firstMatch(line);
        if (m != null) {
          final idx = nameToIndex[m.group(1)!.toLowerCase()];
          if (idx != null) {
            actions.add(ActionEntry(1, idx, 'fold'));
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
                bigBlind != null && bigBlind! > 0
                    ? (amt / bigBlind!).round()
                    : amt.round();
            final isAllIn = m.group(3)!.toLowerCase().contains('all-in');
            final action = isAllIn ? 'all-in' : 'call';
            actions.add(ActionEntry(1, idx, action, amount: amount));
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
                bigBlind != null && bigBlind! > 0
                    ? (amt / bigBlind!).round()
                    : amt.round();
            final isAllIn = m.group(4)!.toLowerCase().contains('all-in');
            final action = isAllIn ? 'all-in' : 'raise';
            actions.add(ActionEntry(1, idx, action, amount: amount));
            actionTags[idx] = '$action $amount';
          }
          continue;
        }
      }
    }

    // Parse turn actions between TURN and RIVER.
    final turnIndex =
        lines.indexWhere((l) => l.startsWith('*** TURN'), flopIndex + 1);
    if (turnIndex != -1) {
      final endIndex =
          lines.indexWhere((l) => l.startsWith('*** RIVER'), turnIndex + 1);
      for (int i = turnIndex + 1;
          i < lines.length && (endIndex == -1 || i < endIndex);
          i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        Match? m;

        m = RegExp(r'^(.+?): folds', caseSensitive: false).firstMatch(line);
        if (m != null) {
          final idx = nameToIndex[m.group(1)!.toLowerCase()];
          if (idx != null) {
            actions.add(ActionEntry(2, idx, 'fold'));
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
                bigBlind != null && bigBlind! > 0
                    ? (amt / bigBlind!).round()
                    : amt.round();
            final isAllIn = m.group(3)!.toLowerCase().contains('all-in');
            final action = isAllIn ? 'all-in' : 'call';
            actions.add(ActionEntry(2, idx, action, amount: amount));
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
                bigBlind != null && bigBlind! > 0
                    ? (amt / bigBlind!).round()
                    : amt.round();
            final isAllIn = m.group(4)!.toLowerCase().contains('all-in');
            final action = isAllIn ? 'all-in' : 'raise';
            actions.add(ActionEntry(2, idx, action, amount: amount));
            actionTags[idx] = '$action $amount';
          }
          continue;
        }
      }
    }

    // Parse river actions after RIVER line.
    final riverIndex = lines.indexWhere((l) => l.startsWith('*** RIVER'));
    if (riverIndex != -1) {
      final endIndex = lines.indexWhere(
          (l) => l.startsWith('*** SHOW') || l.startsWith('*** SUMMARY'),
          riverIndex + 1);
      for (int i = riverIndex + 1;
          i < lines.length && (endIndex == -1 || i < endIndex);
          i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        Match? m;

        m = RegExp(r'^(.+?): folds', caseSensitive: false).firstMatch(line);
        if (m != null) {
          final idx = nameToIndex[m.group(1)!.toLowerCase()];
          if (idx != null) {
            actions.add(ActionEntry(3, idx, 'fold'));
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
                bigBlind != null && bigBlind! > 0
                    ? (amt / bigBlind!).round()
                    : amt.round();
            final isAllIn = m.group(3)!.toLowerCase().contains('all-in');
            final action = isAllIn ? 'all-in' : 'call';
            actions.add(ActionEntry(3, idx, action, amount: amount));
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
                bigBlind != null && bigBlind! > 0
                    ? (amt / bigBlind!).round()
                    : amt.round();
            final isAllIn = m.group(4)!.toLowerCase().contains('all-in');
            final action = isAllIn ? 'all-in' : 'raise';
            actions.add(ActionEntry(3, idx, action, amount: amount));
            actionTags[idx] = '$action $amount';
          }
          continue;
        }
      }
    }

    final stackSizes = <int, int>{};
    for (int i = 0; i < seatEntries.length; i++) {
      final stack = seatEntries[i]['stack'] as double? ?? 0;
      if (bigBlind != null && bigBlind! > 0) {
        stackSizes[i] = (stack / bigBlind!).round();
      } else {
        stackSizes[i] = stack.round();
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
