import '../models/card_model.dart';

class BoardTextureFilterService {
  BoardTextureFilterService();

  bool filter(List<String> board, List<String> filters) {
    if (filters.isEmpty) return true;
    if (board.isEmpty) return false;
    for (final f in filters) {
      switch (f) {
        case 'low':
        case 'lowBoards':
          if (!_isLow(
            board.map((c) => CardModel(rank: c[0], suit: c[1])).toList(),
          )) {
            return false;
          }
          break;
        case 'aceHigh':
          if (!_isAceHigh(
            board.map((c) => CardModel(rank: c[0], suit: c[1])).toList(),
          )) {
            return false;
          }
          break;
        case 'highCard':
          if (!_isHighCard(
            board.map((c) => CardModel(rank: c[0], suit: c[1])).toList(),
          )) {
            return false;
          }
          break;
        case 'paired':
          if (!_isPaired(
            board.map((c) => CardModel(rank: c[0], suit: c[1])).toList(),
          )) {
            return false;
          }
          break;
        default:
          break;
      }
    }
    return true;
  }

  bool isMatch(List<CardModel> board, Map<String, dynamic>? filter) {
    if (filter == null || filter.isEmpty) return true;
    if (board.isEmpty) return false;

    final ranks = board.map((c) => c.rank.toUpperCase()).toList();
    final suits = board.map((c) => c.suit).toList();

    final excluded = <String>{
      for (final r in (filter['excludedRanks'] as List? ?? []))
        r.toString().toUpperCase(),
    };
    if (ranks.any(excluded.contains)) return false;

    final requiredRanks = <String>[
      ...(filter['requiredRanks'] as List? ?? []).map(
        (e) => e.toString().toUpperCase(),
      ),
    ];
    for (final r in requiredRanks) {
      if (!ranks.contains(r)) return false;
    }

    final requiredSuits = <String>[
      ...(filter['requiredSuits'] as List? ?? []).map((e) => e.toString()),
    ];
    for (final s in requiredSuits) {
      if (!suits.contains(s)) return false;
    }

    final textures = _asList(filter['boardTexture']);
    for (final t in textures) {
      switch (t) {
        case 'low':
          if (!_isLow(board)) return false;
          break;
        case 'aceHigh':
          if (!_isAceHigh(board)) return false;
          break;
        case 'highCard':
          if (!_isHighCard(board)) return false;
          break;
        case 'paired':
          if (!_isPaired(board)) return false;
          break;
        case 'straightDrawHeavy':
          if (!_isStraightDrawHeavy(board)) return false;
          break;
        case 'broadway':
          if (!_isBroadway(board)) return false;
          break;
        case 'rainbow':
          if (!_isRainbow(board)) return false;
          break;
        case 'twoTone':
          if (!_isTwoTone(board)) return false;
          break;
        case 'monotone':
          if (!_isMonotone(board)) return false;
          break;
        default:
          break;
      }
    }

    final pattern = filter['suitPattern']?.toString();
    if (pattern != null) {
      switch (pattern) {
        case 'rainbow':
          if (!_isRainbow(board)) return false;
          break;
        case 'twoTone':
          if (!_isTwoTone(board)) return false;
          break;
        case 'monotone':
          if (!_isMonotone(board)) return false;
          break;
        default:
          break;
      }
    }

    return true;
  }

  List<String> _asList(dynamic v) {
    if (v == null) return const [];
    if (v is List) return [for (final e in v) e.toString()];
    return [v.toString()];
  }

  bool _isLow(List<CardModel> board) =>
      board.every((c) => _rankValue(c.rank) <= 8);

  bool _isAceHigh(List<CardModel> board) =>
      board.any((c) => _rankValue(c.rank) == 14);

  bool _isHighCard(List<CardModel> board) =>
      board.any((c) => _rankValue(c.rank) >= 10);

  bool _isPaired(List<CardModel> board) {
    final ranks = board.map((c) => c.rank).toList();
    return ranks.toSet().length < ranks.length;
  }

  bool _isRainbow(List<CardModel> board) =>
      board.map((c) => c.suit).toSet().length == 3;

  bool _isTwoTone(List<CardModel> board) =>
      board.map((c) => c.suit).toSet().length == 2;

  bool _isMonotone(List<CardModel> board) =>
      board.map((c) => c.suit).toSet().length == 1;

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
