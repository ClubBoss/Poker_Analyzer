import 'package:characters/characters.dart';

enum BoardTexture {
  rainbow,
  twoTone,
  monotone,
  paired,
  aceHigh,
  lowConnected,
  broadwayHeavy,
}

String _cardSuit(String c) => c.isEmpty ? '' : c.characters.last;
String _cardRank(String c) => c.characters.skipLast(1).string;
int _rankToIntFlexible(String rank) {
  final r = rank.toUpperCase();
  if (r == 'T' || r == '10') return 10;
  switch (r) {
    case 'A':
      return 14;
    case 'K':
      return 13;
    case 'Q':
      return 12;
    case 'J':
      return 11;
  }
  return int.tryParse(r) ?? 0;
}

List<String> parseBoard(dynamic board) {
  if (board is List) {
    return board.take(5).cast<String>().toList();
  }
  if (board is String) {
    final clean = board.replaceAll(RegExp(r'[^0-9a-zA-Z♣♠♥♦]'), '');
    final chars = clean.characters;
    final cards = <String>[];
    var i = 0;
    while (i < chars.length - 1 && cards.length < 5) {
      var rank = chars.elementAt(i);
      i++;
      if (rank == '1' && i < chars.length && chars.elementAt(i) == '0') {
        rank = '10';
        i++;
      }
      if (i >= chars.length) break;
      final suit = chars.elementAt(i);
      i++;
      cards.add('$rank$suit');
    }
    return cards;
  }
  return <String>[];
}

Set<BoardTexture> classifyFlop(List<String> cards) {
  final res = <BoardTexture>{};
  if (cards.length < 3) {
    return res;
  }
  final flop = cards.take(3).toList();

  final ranks = <int>[];
  final suitCounts = <String, int>{};
  for (final raw in flop) {
    final suit = _cardSuit(raw).toLowerCase();
    final rank = _cardRank(raw);
    suitCounts[suit] = (suitCounts[suit] ?? 0) + 1;
    ranks.add(_rankToIntFlexible(rank));
  }

  if (suitCounts.length == 1) {
    res.add(BoardTexture.monotone);
  } else if (suitCounts.length == 2) {
    res.add(BoardTexture.twoTone);
  } else {
    res.add(BoardTexture.rainbow);
  }

  ranks.sort();

  if (ranks.toSet().length < 3) {
    res.add(BoardTexture.paired);
  }

  if (ranks.contains(14)) {
    res.add(BoardTexture.aceHigh);
  }

  if (ranks.last <= 9 && ranks.last - ranks.first <= 4) {
    res.add(BoardTexture.lowConnected);
  }

  final broadwayCount = ranks.where((r) => r >= 10).length;
  if (broadwayCount >= 2) {
    res.add(BoardTexture.broadwayHeavy);
  }

  return res;
}
