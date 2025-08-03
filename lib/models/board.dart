import 'card_model.dart';

class Board {
  final List<CardModel> flop;
  final CardModel? turn;
  final CardModel? river;

  Board({required this.flop, this.turn, this.river});

  List<CardModel> get cards => [
        ...flop,
        if (turn != null) turn!,
        if (river != null) river!,
      ];
}

