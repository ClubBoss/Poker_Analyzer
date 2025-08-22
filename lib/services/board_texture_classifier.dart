import '../models/card_model.dart';

/// Classifies flop boards into descriptive texture tags.
class BoardTextureClassifier {
  BoardTextureClassifier();

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

    // Map ranks and suits.
    final ranks = board.map((c) => _rankValue(c.rank)).toList();
    final suits = board.map((c) => c.suit).toList();

    // Count ranks and suits.
    final rankCounts = <int, int>{};
    final suitCounts = <String, int>{};
    for (var i = 0; i < ranks.length; i++) {
      final r = ranks[i];
      rankCounts[r] = (rankCounts[r] ?? 0) + 1;
      final s = suits[i];
      suitCounts[s] = (suitCounts[s] ?? 0) + 1;
    }

    // Pair related tags.
    final pairCount = rankCounts.values.where((c) => c >= 2).length;
    if (pairCount >= 1) tags.add('paired');
    if (pairCount >= 2) tags.add('twoPaired');
    if (rankCounts.values.any((c) => c >= 3)) tags.add('trip');

    // High/low related tags.
    final maxRank = ranks.reduce((a, b) => a > b ? a : b);
    if (maxRank >= 10) {
      tags.add('high');
    } else {
      tags.add('low');
    }
    if (ranks.contains(14)) tags.add('aceHigh');
    if (ranks.every((r) => r >= 10)) tags.add('broadway');

    // Suit based tags.
    final uniqueSuits = suitCounts.length;
    final maxSuitCount = suitCounts.values.isEmpty
        ? 0
        : suitCounts.values.reduce((a, b) => a > b ? a : b);
    if (uniqueSuits == 1) {
      tags.add('monotone');
    } else if (maxSuitCount >= board.length - 1) {
      tags.add('flushDraw');
    } else if (uniqueSuits == board.length) {
      tags.add('rainbow');
    }

    // Prepare ranks for straight evaluation (treat Ace as low as well).
    final straightRanks = rankCounts.keys.toSet();
    if (straightRanks.contains(14)) straightRanks.add(1);
    final sortedRanks = straightRanks.toList()..sort();

    // Connected / disconnected.
    if (sortedRanks.last - sortedRanks.first <= 4) {
      tags.add('connected');
    } else {
      tags.add('disconnected');
    }

    // Straight draw detection: any 3 ranks within a span of four.
    var hasStraightDraw = false;
    for (var i = 0; i < sortedRanks.length && !hasStraightDraw; i++) {
      var count = 1;
      for (var j = i + 1; j < sortedRanks.length; j++) {
        if (sortedRanks[j] - sortedRanks[i] <= 4) {
          count++;
          if (count >= 3) {
            hasStraightDraw = true;
            break;
          }
        } else {
          break;
        }
      }
    }
    if (hasStraightDraw) tags.add('straightDraw');

    // Wet vs dry.
    if (tags.contains('flushDraw') ||
        tags.contains('straightDraw') ||
        tags.contains('paired') ||
        tags.contains('twoPaired') ||
        tags.contains('trip')) {
      tags.add('wet');
    } else {
      tags.add('dry');
    }

    return tags;
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
