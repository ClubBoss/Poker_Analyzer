import '../models/board_stages.dart';
import '../models/card_model.dart';

class BoardFilteringServiceV2 {
  const BoardFilteringServiceV2();

  bool isMatch(BoardStages board, Set<String> requiredTags, {Set<String>? excludedTags}) {
    final tags = _evaluate(board);
    if (excludedTags != null && excludedTags.any(tags.contains)) {
      return false;
    }
    for (final t in requiredTags) {
      if (!tags.contains(t)) return false;
    }
    return true;
  }

  Set<String> _evaluate(BoardStages board) {
    final all = [...board.flop, board.turn, board.river];
    final cards = all.map((c) => CardModel(rank: c[0], suit: c[1])).toList();
    final tags = <String>{};

    final ranks = cards.map((c) => c.rank).toList();
    final suits = cards.map((c) => c.suit).toList();
    final values = cards.map((c) => _rankValue(c.rank)).toList();

    if (ranks.toSet().length < ranks.length) {
      tags.add('paired');
    }

    if (values.any((v) => v >= 10)) tags.add('highCard');
    if (values.any((v) => v == 14)) tags.add('aceHigh');
    if (values.every((v) => v <= 9)) tags.add('low');

    final broadwayCount = values.where((v) => v >= 10).length;
    if (broadwayCount >= 3) tags.add('broadwayHeavy');
    if (broadwayCount == 3) tags.add('tripleBroadway');

    final suitCounts = <String, int>{};
    for (final s in suits) {
      suitCounts[s] = (suitCounts[s] ?? 0) + 1;
    }
    if (suitCounts.values.any((c) => c >= 4)) {
      tags.add('fourToFlush');
      tags.add('flushDraw');
    }
    if (suitCounts.values.any((c) => c == 5)) {
      tags.add('flush');
    }

    if (_isStraightDrawHeavy(values)) {
      tags.add('straightDrawHeavy');
    }

    return tags;
  }

  bool _isStraightDrawHeavy(List<int> values) {
    values.sort();
    return values.last - values.first <= 4;
  }

  int _rankValue(String r) {
    switch (r.toUpperCase()) {
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
      case '9':
        return 9;
      case '8':
        return 8;
      case '7':
        return 7;
      case '6':
        return 6;
      case '5':
        return 5;
      case '4':
        return 4;
      case '3':
        return 3;
      case '2':
        return 2;
      default:
        return 0;
    }
  }
}
