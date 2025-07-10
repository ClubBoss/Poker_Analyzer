import '../converter_format_capabilities.dart';
import '../converter_plugin.dart';
import 'package:poker_analyzer/models/saved_hand.dart';
import 'package:poker_analyzer/models/card_model.dart';
import 'package:poker_analyzer/models/action_entry.dart';
import 'package:poker_analyzer/models/player_model.dart';

class WpnHandHistoryConverter extends ConverterPlugin {
  WpnHandHistoryConverter()
      : super(
          formatId: 'wpn_hand_history',
          description: 'Winning Poker Network hand history format',
          capabilities: const ConverterFormatCapabilities(
            supportsImport: true,
            supportsExport: false,
            requiresBoard: false,
            supportsMultiStreet: false,
          ),
        );

  CardModel? _parseCard(String token) {
    if (token.length < 2) return null;
    final rank = token.substring(0, token.length - 1).toUpperCase();
    final suitChar = token[token.length - 1].toLowerCase();
    switch (suitChar) {
      case 'h':
        return CardModel(rank: rank, suit: '♥');
      case 'd':
        return CardModel(rank: rank, suit: '♦');
      case 'c':
        return CardModel(rank: rank, suit: '♣');
      case 's':
        return CardModel(rank: rank, suit: '♠');
    }
    return null;
  }

  double _amount(String s) => double.tryParse(s.replaceAll(',', '.')) ?? 0;

  @override
  SavedHand? convertFrom(String externalData) {
    final lines = externalData.split(RegExp(r'\r?\n'));
    if (lines.isEmpty || !lines.first.toLowerCase().contains('winning poker')) {
      return null;
    }
    final seatRegex =
        RegExp(r'^Seat (\d+):\s*(.+?) \(([^)]+)\)', caseSensitive: false);
    final seatEntries = <Map<String, dynamic>>[];
    for (final line in lines) {
      final m = seatRegex.firstMatch(line.trim());
      if (m != null) {
        seatEntries.add({
          'seat': int.parse(m.group(1)!),
          'name': m.group(2)!.trim(),
          'stack': _amount(m.group(3)!),
        });
      }
    }
    if (seatEntries.isEmpty) return null;
    seatEntries.sort((a, b) => (a['seat'] as int).compareTo(b['seat'] as int));
    final playerCount = seatEntries.length;

    String? heroName;
    List<CardModel> heroCards = [];
    for (final line in lines) {
      final m = RegExp(r'^Dealt to (.+?) \[(.+?) (.+?)\]').firstMatch(line.trim());
      if (m != null) {
        heroName = m.group(1)!.trim();
        final c1 = _parseCard(m.group(2)!);
        final c2 = _parseCard(m.group(3)!);
        if (c1 != null && c2 != null) heroCards = [c1, c2];
        break;
      }
    }
    final nameToIndex = <String, int>{};
    for (int i = 0; i < playerCount; i++) {
      nameToIndex[seatEntries[i]['name'].toString().toLowerCase()] = i;
    }
    int heroIndex = 0;
    if (heroName != null) {
      heroIndex = nameToIndex[heroName.toLowerCase()] ?? 0;
    }
    final playerCards = List.generate(playerCount, (_) => <CardModel>[]);
    if (heroCards.isNotEmpty) playerCards[heroIndex] = heroCards;
    final stackSizes = <int, int>{};
    for (int i = 0; i < playerCount; i++) {
      stackSizes[i] = (seatEntries[i]['stack'] as double).round();
    }
    final actions = <ActionEntry>[];
    bool preflop = false;
    for (final line in lines) {
      final t = line.trim();
      if (t.startsWith('*** HOLE CARDS')) preflop = true;
      if (t.startsWith('*** FLOP')) preflop = false;
      if (!preflop) continue;
      Match? m;
      m = RegExp(r'^(.+?): folds').firstMatch(t);
      if (m != null) {
        final idx = nameToIndex[m.group(1)!.toLowerCase()];
        if (idx != null) actions.add(ActionEntry(0, idx, 'fold'));
        continue;
      }
      m = RegExp(r'^(.+?): checks').firstMatch(t);
      if (m != null) {
        final idx = nameToIndex[m.group(1)!.toLowerCase()];
        if (idx != null) actions.add(ActionEntry(0, idx, 'check'));
        continue;
      }
      m = RegExp(r'^(.+?): calls ([\d.,]+)').firstMatch(t);
      if (m != null) {
        final idx = nameToIndex[m.group(1)!.toLowerCase()];
        if (idx != null) actions.add(ActionEntry(0, idx, 'call', amount: _amount(m.group(2)!)));
        continue;
      }
      m = RegExp(r'^(.+?): bets ([\d.,]+)').firstMatch(t);
      if (m != null) {
        final idx = nameToIndex[m.group(1)!.toLowerCase()];
        if (idx != null) actions.add(ActionEntry(0, idx, 'bet', amount: _amount(m.group(2)!)));
        continue;
      }
      m = RegExp(r'^(.+?): raises .* to ([\d.,]+)').firstMatch(t);
      if (m != null) {
        final idx = nameToIndex[m.group(1)!.toLowerCase()];
        if (idx != null) actions.add(ActionEntry(0, idx, 'raise', amount: _amount(m.group(2)!)));
        continue;
      }
    }
    final positions = {for (int i = 0; i < playerCount; i++) i: ''};
    return SavedHand(
      name: '',
      heroIndex: heroIndex,
      heroPosition: positions[heroIndex] ?? '',
      numberOfPlayers: playerCount,
      playerCards: playerCards,
      boardCards: const [],
      boardStreet: 0,
      actions: actions,
      stackSizes: stackSizes,
      playerPositions: positions,
      comment: '',
      playerTypes: {for (int i = 0; i < playerCount; i++) i: PlayerType.unknown},
    );
  }
}
