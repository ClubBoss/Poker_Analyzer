enum BoardTexture { rainbow, twoTone, monotone, paired, aceHigh, lowConnected, broadwayHeavy }

int _rankToInt(String rank) {
  switch (rank.toUpperCase()) {
    case 'A':
      return 14;
    case 'K':
      return 13;
    case 'Q':
      return 12;
    case 'J':
      return 11;
    case 'T':
      return 10;
    default:
      return int.tryParse(rank) ?? 0;
  }
}

Set<BoardTexture> classifyFlop(List<String> cards) {
  final res = <BoardTexture>{};
  if (cards.length < 3) {
    return res;
  }
  final flop = cards.take(3).toList();

  final suitCounts = <String, int>{};
  for (final c in flop) {
    if (c.length < 2) continue;
    final suit = c[1].toLowerCase();
    suitCounts[suit] = (suitCounts[suit] ?? 0) + 1;
  }
  if (suitCounts.length == 1) {
    res.add(BoardTexture.monotone);
  } else if (suitCounts.length == 2) {
    res.add(BoardTexture.twoTone);
  } else {
    res.add(BoardTexture.rainbow);
  }

  final ranks = flop.map((c) => _rankToInt(c[0])).toList()..sort();

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

