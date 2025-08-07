import '../models/card_model.dart';
import '../models/v2/training_pack_spot.dart';

/// Classifies flop boards into descriptive texture tags.
class BoardTextureClassifier {
  const BoardTextureClassifier();

  /// Classifies [flop] such as `'7c5s2h'` into a set of texture tags.
  Set<String> classify(String flop) {
    final cards = <CardModel>[];
    final cleaned = flop.replaceAll(RegExp(r'\s+'), '');
    for (var i = 0; i + 1 < cleaned.length; i += 2) {
      cards.add(CardModel(rank: cleaned[i], suit: cleaned[i + 1]));
    }
    return classifyCards(cards);
  }

  /// Returns texture tags for [board] represented by [CardModel]s.
  Set<String> classifyCards(List<CardModel> board) {
    final tags = <String>{};
    if (board.isEmpty) return tags;

    final ranks = board.map((c) => _rankValue(c.rank)).toList()..sort();
    final suits = board.map((c) => c.suit).toList();

    // Duplication checks
    final rankCounts = <int, int>{};
    for (final r in ranks) {
      rankCounts[r] = (rankCounts[r] ?? 0) + 1;
    }
    if (rankCounts.values.contains(3)) {
      tags.add('trip');
    }
    if (rankCounts.values.any((c) => c >= 2)) {
      tags.add('paired');
    } else {
      tags.add('unpaired');
    }

    // Highest rank categories
    final maxRank = ranks.last;
    if (maxRank >= 11) {
      tags.add('high');
    } else if (maxRank >= 9) {
      tags.add('mid');
    } else {
      tags.add('low');
    }

    // Specific high-card tags
    if (ranks.contains(14)) tags.add('aceHigh');
    if (ranks.contains(13)) tags.add('kingHigh');
    if (ranks.every((r) => r >= 10)) tags.add('broadway');

    // Suit distribution
    final uniqueSuits = suits.toSet().length;
    if (uniqueSuits == 1) {
      tags.add('monotone');
    } else if (uniqueSuits == 2) {
      tags.add('twoTone');
    } else {
      tags.add('rainbow');
    }

    // Connectedness
    if (ranks.last - ranks.first <= 4) {
      tags.add('connected');
    } else {
      tags.add('disconnected');
    }

    // Wet vs dry
    final hasFlushDraw = uniqueSuits <= 2;
    final hasStraightDraw = ranks.last - ranks.first <= 4;
    if (hasFlushDraw || hasStraightDraw || tags.contains('paired')) {
      tags.add('wet');
    } else {
      tags.add('dry');
    }

    return tags;
  }

  /// Annotates each [TrainingPackSpot] with `boardTextureTags` in its meta map.
  void classifyAll(Iterable<TrainingPackSpot> spots) {
    for (final s in spots) {
      final board = [
        for (final c in s.board) CardModel(rank: c[0], suit: c[1])
      ];
      final tags = classifyCards(board).toList();
      s.meta['boardTextureTags'] = tags;
    }
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
