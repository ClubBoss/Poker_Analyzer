import '../converter_format_capabilities.dart';
import '../converter_plugin.dart';
import 'dart:convert';
import 'package:poker_analyzer/models/saved_hand.dart';
import 'package:poker_analyzer/models/card_model.dart';
import 'package:poker_analyzer/helpers/hand_history_parsing.dart';
import 'package:poker_analyzer/models/action_entry.dart';
import 'package:poker_analyzer/models/player_model.dart';
import 'package:poker_analyzer/helpers/poker_position_helper.dart';

class GGPokerHandHistoryConverter extends ConverterPlugin {
  GGPokerHandHistoryConverter()
      : super(
          formatId: 'ggpoker_hand_history',
          description: 'GGPoker hand history format',
          capabilities: const ConverterFormatCapabilities(
            supportsImport: true,
            supportsExport: false,
            requiresBoard: false,
            supportsMultiStreet: true,
          ),
        );


  double _amount(String s) => double.tryParse(s.replaceAll(',', '')) ?? 0;

  @override
  SavedHand? convertFrom(String externalData) {
    final lines = LineSplitter.split(externalData).map((e) => e.trim()).toList();
    final header = _parseHeader(lines);
    if (header == null) return null;
    final seats = _parseSeats(lines);
    if (seats.isEmpty) return null;
    final hero = _parseHero(lines, seats);
    final actions = _parseActions(lines, hero.nameToIndex);
    return _buildSavedHand(header, seats, hero, actions);
  }

  // Parses the hand id and table name from the header lines.
  _Header? _parseHeader(List<String> lines) {
    if (lines.isEmpty) return null;
    final idMatch = RegExp(r'^Hand #(\d+)').firstMatch(lines.first);
    if (idMatch == null) return null;
    final handId = idMatch.group(1)!;
    String tableName = '';
    for (final line in lines) {
      final tm =
          RegExp(r"^Table '([^']+)'", caseSensitive: false).firstMatch(line);
      if (tm != null) {
        tableName = tm.group(1)!.trim();
        break;
      }
    }
    return _Header(handId, tableName);
  }

  // Extracts seat information including player name and stack size.
  List<Map<String, dynamic>> _parseSeats(List<String> lines) {
    final seatEntries = <Map<String, dynamic>>[];
    final seatRegex = RegExp(r'^Seat (\d+):\s*(.+?)\s*\(([^)]+)\)');
    for (final line in lines) {
      final sm = seatRegex.firstMatch(line);
      if (sm != null) {
        seatEntries.add({
          'seat': int.parse(sm.group(1)!),
          'name': sm.group(2)!.trim(),
          'stack': _amount(sm.group(3)!.replaceAll(RegExp(r'[^0-9.,]'), '')),
        });
      }
    }
    seatEntries.sort((a, b) => (a['seat'] as int).compareTo(b['seat'] as int));
    return seatEntries;
  }

  // Determines hero info, player cards, and index mapping.
  _HeroInfo _parseHero(
    List<String> lines,
    List<Map<String, dynamic>> seatEntries,
  ) {
    String? heroName;
    List<CardModel> heroCards = [];
    for (final line in lines) {
      final m = RegExp(r'^Dealt to (.+?) \[(.+?) (.+?)\]').firstMatch(line);
      if (m != null) {
        heroName = m.group(1)!.trim();
        final c1 = parseCard(m.group(2)!);
        final c2 = parseCard(m.group(3)!);
        if (c1 != null && c2 != null) heroCards = [c1, c2];
        break;
      }
    }
    final playerCount = seatEntries.length;
    final nameToIndex = <String, int>{};
    for (int i = 0; i < playerCount; i++) {
      nameToIndex[seatEntries[i]['name'].toString().toLowerCase()] = i;
    }
    int heroIndex = 0;
    final playerCards = List.generate(playerCount, (_) => <CardModel>[]);
    if (heroName != null) {
      heroIndex = nameToIndex[heroName.toLowerCase()] ?? 0;
      if (heroCards.isNotEmpty) playerCards[heroIndex] = heroCards;
    }
    return _HeroInfo(heroIndex, playerCards, nameToIndex);
  }

  // Parses all player actions street by street.
  List<ActionEntry> _parseActions(
    List<String> lines,
    Map<String, int> nameToIndex,
  ) {
    final actions = <ActionEntry>[];
    int street = 0;
    for (final line in lines) {
      if (line.startsWith('*** FLOP')) street = 1;
      if (line.startsWith('*** TURN')) street = 2;
      if (line.startsWith('*** RIVER')) street = 3;
      Match? m;
      m = RegExp(r'^(.+?): folds').firstMatch(line);
      if (m != null) {
        final idx = nameToIndex[m.group(1)!.toLowerCase()];
        if (idx != null) actions.add(ActionEntry(street, idx, 'fold'));
        continue;
      }
      m = RegExp(r'^(.+?): checks').firstMatch(line);
      if (m != null) {
        final idx = nameToIndex[m.group(1)!.toLowerCase()];
        if (idx != null) actions.add(ActionEntry(street, idx, 'check'));
        continue;
      }
      m = RegExp(r'^(.+?): calls ([\d,.]+)').firstMatch(line);
      if (m != null) {
        final idx = nameToIndex[m.group(1)!.toLowerCase()];
        if (idx != null) {
          actions.add(
              ActionEntry(street, idx, 'call', amount: _amount(m.group(2)!)));
        }
        continue;
      }
      m = RegExp(r'^(.+?): bets ([\d,.]+)').firstMatch(line);
      if (m != null) {
        final idx = nameToIndex[m.group(1)!.toLowerCase()];
        if (idx != null) {
          actions.add(
              ActionEntry(street, idx, 'bet', amount: _amount(m.group(2)!)));
        }
        continue;
      }
      m = RegExp(r'^(.+?): raises .* to ([\d,.]+)').firstMatch(line);
      if (m != null) {
        final idx = nameToIndex[m.group(1)!.toLowerCase()];
        if (idx != null) {
          actions.add(
              ActionEntry(street, idx, 'raise', amount: _amount(m.group(2)!)));
        }
        continue;
      }
    }
    return actions;
  }

  // Builds the final SavedHand object.
  SavedHand _buildSavedHand(
    _Header header,
    List<Map<String, dynamic>> seatEntries,
    _HeroInfo hero,
    List<ActionEntry> actions,
  ) {
    final playerCount = seatEntries.length;
    final stackSizes = <int, int>{};
    for (int i = 0; i < playerCount; i++) {
      final stack = seatEntries[i]['stack'] as double? ?? 0;
      stackSizes[i] = stack.round();
    }
    final positions = <int, String>{};
    try {
      final order = getPositionList(playerCount);
      for (int i = 0; i < playerCount; i++) {
        positions[i] = order[i % order.length];
      }
    } catch (_) {
      for (int i = 0; i < playerCount; i++) {
        positions[i] = '';
      }
    }
    return SavedHand(
      name: header.handId,
      heroIndex: hero.heroIndex,
      heroPosition: positions[hero.heroIndex] ?? 'BTN',
      numberOfPlayers: playerCount,
      playerCards: hero.playerCards,
      boardCards: const [],
      boardStreet: 0,
      actions: actions,
      stackSizes: stackSizes,
      playerPositions: positions,
      comment: header.tableName,
      playerTypes: {for (var i = 0; i < playerCount; i++) i: PlayerType.unknown},
    );
  }
}

class _Header {
  _Header(this.handId, this.tableName);
  final String handId;
  final String tableName;
}

class _HeroInfo {
  _HeroInfo(this.heroIndex, this.playerCards, this.nameToIndex);
  final int heroIndex;
  final List<List<CardModel>> playerCards;
  final Map<String, int> nameToIndex;
}

