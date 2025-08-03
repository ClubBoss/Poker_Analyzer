class BoardTextureFilterService {
  const BoardTextureFilterService();

  bool filter(List<String> board, List<String> filters) {
    if (filters.isEmpty) return true;
    if (board.isEmpty) return false;
    for (final f in filters) {
      switch (f) {
        case 'low':
        case 'lowBoards':
          if (!_isLow(board)) return false;
          break;
        case 'aceHigh':
          if (!_isAceHigh(board)) return false;
          break;
        case 'paired':
          if (!_isPaired(board)) return false;
          break;
        default:
          break;
      }
    }
    return true;
  }

  bool _isLow(List<String> board) =>
      board.every((c) => _rankValue(c[0]) <= 8);

  bool _isAceHigh(List<String> board) =>
      board.any((c) => _rankValue(c[0]) == 14);

  bool _isPaired(List<String> board) {
    final ranks = board.map((c) => c[0]).toList();
    return ranks.toSet().length < ranks.length;
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
