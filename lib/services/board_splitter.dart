import '../models/board.dart';
import '../models/card_model.dart';

class BoardSplitter {
  static Board split(List<CardModel> cards) {
    final flop = cards.length >= 3 ? cards.sublist(0, 3) : <CardModel>[];
    final turn = cards.length >= 4 ? cards[3] : null;
    final river = cards.length >= 5 ? cards[4] : null;
    return Board(flop: flop, turn: turn, river: river);
  }
}
