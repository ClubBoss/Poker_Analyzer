import 'card_model.dart';

class SpotSeed {
  final List<CardModel> board;
  final List<CardModel> hand;
  final String position;
  final List<String> previousActions;
  final String targetStreet;
  final List<String> tags;

  SpotSeed({
    required this.board,
    required this.hand,
    required this.position,
    required this.previousActions,
    required this.targetStreet,
    List<String>? tags,
  }) : tags = tags ?? [];
}
