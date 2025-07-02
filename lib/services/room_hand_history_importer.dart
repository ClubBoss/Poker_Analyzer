import '../import_export/converter_pipeline.dart';
import 'package:poker_ai_analyzer/plugins/plugin_loader.dart';
import 'package:poker_ai_analyzer/plugins/plugin_manager.dart';
import 'package:poker_ai_analyzer/plugins/converter_registry.dart';
import '../services/service_registry.dart';
import '../models/saved_hand.dart';
import '../helpers/poker_position_helper.dart';
import '../models/card_model.dart';
import '../models/action_entry.dart';

class RoomHandHistoryImporter {
  RoomHandHistoryImporter._(this._pipeline);

  static Future<RoomHandHistoryImporter> create() async {
    final loader = PluginLoader();
    final manager = PluginManager();
    final registry = ServiceRegistry();
    await loader.loadAll(registry, manager);
    final converterRegistry = registry.get<ConverterRegistry>();
    final pipeline = ConverterPipeline(converterRegistry);
    return RoomHandHistoryImporter._(pipeline);
  }

  final ConverterPipeline _pipeline;

  List<SavedHand> parse(String text) {
    final hands = <SavedHand>[];
    final segments = _split(text);
    final converters = _pipeline.availableConverters(supportsImport: true);
    for (final seg in segments) {
      SavedHand? hand;
      for (final info in converters) {
        hand = _pipeline.tryImport(info.formatId, seg);
        if (hand != null) break;
      }
      hand ??= _parseGg(seg);
      if (hand != null) hands.add(hand);
    }
    return hands;
  }

  List<String> _split(String text) {
    final lines = text.split(RegExp(r'\r?\n'));
    final hands = <String>[];
    final buffer = StringBuffer();
    bool isFirst = true;
    for (final line in lines) {
      final trimmed = line.trim();
      if (!isFirst && (trimmed.startsWith('PokerStars Hand #') ||
          trimmed.startsWith('Hand #') ||
          trimmed.startsWith('GGPoker Hand #'))) {
        hands.add(buffer.toString().trim());
        buffer.clear();
      }
      buffer.writeln(line);
      isFirst = false;
    }
    if (buffer.isNotEmpty) hands.add(buffer.toString().trim());
    return hands.where((h) => h.isNotEmpty).toList();
  }

  SavedHand? _parseGg(String text) {
    final lines = text.split(RegExp(r'\r?\n')).map((e) => e.trim()).toList();
    if (lines.isEmpty) return null;
    final idMatch = RegExp(r'^Hand #(\d+)').firstMatch(lines.first);
    if (idMatch == null) return null;
    final handId = idMatch.group(1)!;
    String tableName = '';
    final seatEntries = <Map<String, dynamic>>[];
    final seatRegex = RegExp(r'^Seat (\d+):\s*(.+?)\s*\(([^)]+)\)');
    for (final line in lines) {
      final tm = RegExp(r"^Table '([^']+)'", caseSensitive: false).firstMatch(line);
      if (tm != null) tableName = tm.group(1)!.trim();
      final sm = seatRegex.firstMatch(line);
      if (sm != null) {
        seatEntries.add({
          'seat': int.parse(sm.group(1)!),
          'name': sm.group(2)!.trim(),
          'stack': double.tryParse(sm.group(3)!.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0,
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
        final c1 = _parseCard(m.group(2)!);
        final c2 = _parseCard(m.group(3)!);
        if (c1 != null && c2 != null) heroCards = [c1, c2];
        break;
      }
    }
    int heroIndex = 0;
    final playerCards = List.generate(playerCount, (_) => <CardModel>[]);
    final nameToIndex = <String, int>{};
    for (int i = 0; i < playerCount; i++) {
      nameToIndex[seatEntries[i]['name'].toString().toLowerCase()] = i;
    }
    if (heroName != null) {
      heroIndex = nameToIndex[heroName.toLowerCase()] ?? 0;
      if (heroCards.isNotEmpty) playerCards[heroIndex] = heroCards;
    }
    final stackSizes = <int, int>{};
    for (int i = 0; i < playerCount; i++) {
      stackSizes[i] = (seatEntries[i]['stack'] as double).round();
    }
    final actions = <ActionEntry>[];
    int street = 0;
    for (final line in lines) {
      if (line.startsWith('*** FLOP')) street = 1;
      if (line.startsWith('*** TURN')) street = 2;
      if (line.startsWith('*** RIVER')) street = 3;
      final mFold = RegExp(r'^(.+?): folds').firstMatch(line);
      if (mFold != null) {
        final idx = nameToIndex[mFold.group(1)!.toLowerCase()];
        if (idx != null) actions.add(ActionEntry(street, idx, 'fold'));
        continue;
      }
      final mCheck = RegExp(r'^(.+?): checks').firstMatch(line);
      if (mCheck != null) {
        final idx = nameToIndex[mCheck.group(1)!.toLowerCase()];
        if (idx != null) actions.add(ActionEntry(street, idx, 'check'));
        continue;
      }
      final mCall = RegExp(r'^(.+?): calls ([\d,.]+)').firstMatch(line);
      if (mCall != null) {
        final idx = nameToIndex[mCall.group(1)!.toLowerCase()];
        if (idx != null) {
          final amt = double.tryParse(mCall.group(2)!.replaceAll(',', ''));
          actions.add(ActionEntry(street, idx, 'call', amount: amt));
        }
        continue;
      }
      final mBet = RegExp(r'^(.+?): bets ([\d,.]+)').firstMatch(line);
      if (mBet != null) {
        final idx = nameToIndex[mBet.group(1)!.toLowerCase()];
        if (idx != null) {
          final amt = double.tryParse(mBet.group(2)!.replaceAll(',', ''));
          actions.add(ActionEntry(street, idx, 'bet', amount: amt));
        }
        continue;
      }
      final mRaise = RegExp(r'^(.+?): raises .* to ([\d,.]+)').firstMatch(line);
      if (mRaise != null) {
        final idx = nameToIndex[mRaise.group(1)!.toLowerCase()];
        if (idx != null) {
          final amt = double.tryParse(mRaise.group(2)!.replaceAll(',', ''));
          actions.add(ActionEntry(street, idx, 'raise', amount: amt));
        }
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
      for (int i = 0; i < playerCount; i++) positions[i] = '';
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
      playerTypes: {for (var i = 0; i < playerCount; i++) i: PlayerType.unknown},
    );
  }

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
}
