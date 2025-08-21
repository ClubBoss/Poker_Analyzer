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
    final lines = LineSplitter.split(
      externalData,
    ).map((e) => e.trim()).toList();
    if (lines.isEmpty) return null;
    final idMatch = RegExp(r'^Hand #(\d+)').firstMatch(lines.first);
    if (idMatch == null) return null;
    final handId = idMatch.group(1)!;
    String tableName = '';
    final seatEntries = <Map<String, dynamic>>[];
    final seatRegex = RegExp(r'^Seat (\d+):\s*(.+?)\s*\(([^)]+)\)');
    for (final line in lines) {
      final tm = RegExp(
        r"^Table '([^']+)'",
        caseSensitive: false,
      ).firstMatch(line);
      if (tm != null) tableName = tm.group(1)!.trim();
      final sm = seatRegex.firstMatch(line);
      if (sm != null) {
        seatEntries.add({
          'seat': int.parse(sm.group(1)!),
          'name': sm.group(2)!.trim(),
          'stack': _amount(sm.group(3)!.replaceAll(RegExp(r'[^0-9.,]'), '')),
        });
      }
    }
    if (seatEntries.isEmpty) return null;
    seatEntries.sort((a, b) => (a['seat'] as int).compareTo(b['seat'] as int));
    final playerCount = seatEntries.length;
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
    final stackSizes = <int, int>{};
    for (int i = 0; i < playerCount; i++) {
      final stack = seatEntries[i]['stack'] as double? ?? 0;
      stackSizes[i] = stack.round();
    }
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
        if (idx != null)
          actions.add(
            ActionEntry(street, idx, 'call', amount: _amount(m.group(2)!)),
          );
        continue;
      }
      m = RegExp(r'^(.+?): bets ([\d,.]+)').firstMatch(line);
      if (m != null) {
        final idx = nameToIndex[m.group(1)!.toLowerCase()];
        if (idx != null)
          actions.add(
            ActionEntry(street, idx, 'bet', amount: _amount(m.group(2)!)),
          );
        continue;
      }
      m = RegExp(r'^(.+?): raises .* to ([\d,.]+)').firstMatch(line);
      if (m != null) {
        final idx = nameToIndex[m.group(1)!.toLowerCase()];
        if (idx != null)
          actions.add(
            ActionEntry(street, idx, 'raise', amount: _amount(m.group(2)!)),
          );
        continue;
      }
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
      name: handId,
      heroIndex: heroIndex,
      heroPosition: positions[heroIndex] ?? 'BTN',
      numberOfPlayers: playerCount,
      playerCards: playerCards,
      boardCards: const [],
      boardStreet: 0,
      actions: actions,
      stackSizes: stackSizes,
      playerPositions: positions,
      comment: tableName,
      playerTypes: {
        for (var i = 0; i < playerCount; i++) i: PlayerType.unknown,
      },
    );
  }
}
