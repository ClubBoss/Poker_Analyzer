import '../models/card_model.dart';

class DynamicBoardTaggerService {
  const DynamicBoardTaggerService();

  /// Tags the given [board] based on common board texture heuristics.
  ///
  /// This method is the primary entry point and is aliased by [tag] for
  /// convenience.
  Set<String> tagBoard(List<CardModel> board) {
    final tags = <String>{};
    if (board.isEmpty) return tags;

    final suits = board.map((c) => c.suit).toList();
    final uniqueSuits = suits.toSet().length;

    if (_isPaired(board)) tags.add('paired');
    if (uniqueSuits == 1) {
      tags..add('monotone');
    } else if (uniqueSuits == 2) {
      tags..add('twoTone');
    } else if (_isRainbow(board)) {
      tags..add('rainbow');
    }

    if (_isLow(board)) tags.add('low');
    if (_isAceHigh(board)) tags.add('aceHigh');
    if (_isHighCard(board)) tags.add('highCard');
    if (_isBroadway(board)) tags.add('broadway');
    if (_isStraightDrawHeavy(board)) tags.add('connected');

    final hasFlushDraw = uniqueSuits <= 2;
    final connected = _isStraightDrawHeavy(board);
    final paired = _isPaired(board);
    if (hasFlushDraw || connected || paired) {
      tags..add('wet')..add('dynamic');
    }
    final isDry = !hasFlushDraw && !connected && !paired && uniqueSuits >= 3;
    if (isDry) tags.add('dry');

    return tags;
  }

  /// Shorthand for [tagBoard] to provide a more concise API.
  Set<String> tag(List<CardModel> board) => tagBoard(board);

  bool _isLow(List<CardModel> board) =>
      board.every((c) => _rankValue(c.rank) <= 8);

  bool _isAceHigh(List<CardModel> board) =>
      board.any((c) => _rankValue(c.rank) == 14);

  bool _isHighCard(List<CardModel> board) =>
      board.any((c) => _rankValue(c.rank) >= 10);

  bool _isPaired(List<CardModel> board) {
    final ranks = board.map((c) => c.rank.toUpperCase()).toList();
    return ranks.toSet().length < ranks.length;
  }

  bool _isRainbow(List<CardModel> board) {
    final uniqueSuits = board.map((c) => c.suit).toSet().length;
    if (board.length <= 4) return uniqueSuits == board.length;
    return uniqueSuits == 4; // maximum distinct suits on a 5-card board
  }

  bool _isStraightDrawHeavy(List<CardModel> board) {
    final values = board.map((c) => _rankValue(c.rank)).toList()..sort();
    return values.last - values.first <= 4;
  }

  bool _isBroadway(List<CardModel> board) =>
      board.every((c) => _rankValue(c.rank) >= 10);

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

