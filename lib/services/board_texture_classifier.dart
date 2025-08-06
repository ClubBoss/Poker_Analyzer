import '../models/card_model.dart';
import '../models/board_texture_tag.dart';
import '../models/v2/training_pack_spot.dart';

/// Classifies board textures for generated training spots.
class BoardTextureClassifier {
  const BoardTextureClassifier();

  /// Returns a set of tags describing [board]'s texture.
  Set<BoardTextureTag> classify(List<CardModel> board) {
    final tags = <BoardTextureTag>{};
    if (board.isEmpty) return tags;

    final ranks = board.map((c) => _rankValue(c.rank)).toList()..sort();
    final suits = board.map((c) => c.suit).toList();

    // Duplication checks
    final rankCounts = <int, int>{};
    for (final r in ranks) {
      rankCounts[r] = (rankCounts[r] ?? 0) + 1;
    }
    if (rankCounts.values.contains(3)) {
      tags.add(BoardTextureTag.trip);
    }
    if (rankCounts.values.any((c) => c >= 2)) {
      tags.add(BoardTextureTag.paired);
    }

    // Highest rank
    final maxRank = ranks.last;
    if (maxRank == 14) {
      tags.add(BoardTextureTag.aceHigh);
      tags.add(BoardTextureTag.high);
    } else if (maxRank == 13) {
      tags.add(BoardTextureTag.kingHigh);
      tags.add(BoardTextureTag.high);
    } else if (maxRank >= 10) {
      tags.add(BoardTextureTag.high);
    } else {
      tags.add(BoardTextureTag.low);
    }

    // Suit distribution
    final uniqueSuits = suits.toSet().length;
    if (uniqueSuits == 1) {
      tags.add(BoardTextureTag.monotone);
    } else if (uniqueSuits == 2) {
      tags.add(BoardTextureTag.twoTone);
    } else {
      tags.add(BoardTextureTag.rainbow);
    }

    // Connectedness
    if (ranks.last - ranks.first <= 4) {
      tags.add(BoardTextureTag.straighty);
    } else {
      tags.add(BoardTextureTag.disconnected);
    }

    // Wet vs dry
    final hasFlushDraw = uniqueSuits <= 2;
    final hasStraightDraw = ranks.last - ranks.first <= 4;
    if (hasFlushDraw || hasStraightDraw || tags.contains(BoardTextureTag.paired)) {
      tags.add(BoardTextureTag.wet);
    } else {
      tags.add(BoardTextureTag.dry);
    }

    return tags;
  }

  /// Annotates each [TrainingPackSpot] with `boardTextureTags` in its meta map.
  void classifyAll(Iterable<TrainingPackSpot> spots) {
    for (final s in spots) {
      final board = [
        for (final c in s.board) CardModel(rank: c[0], suit: c[1])
      ];
      final tags = classify(board).map((e) => e.name).toList();
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
