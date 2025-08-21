import 'card_model.dart';

class FullBoard {
  final List<CardModel> flop;
  final CardModel? turn;
  final CardModel? river;
  final Set<String> textureTags;

  const FullBoard({
    required this.flop,
    this.turn,
    this.river,
    this.textureTags = const {},
  });

  List<CardModel> get cards => [
        ...flop,
        if (turn != null) turn!,
        if (river != null) river!,
      ];

  @override
  String toString() => cards.map((c) => c.toString()).join(' ');

  String toYAML() {
    final buffer = StringBuffer();
    buffer.writeln('flop: ${flop.map((c) => c.toString()).join(' ')}');
    if (turn != null) buffer.writeln('turn: ${turn.toString()}');
    if (river != null) buffer.writeln('river: ${river.toString()}');
    if (textureTags.isNotEmpty) {
      buffer.writeln('tags: ${textureTags.join(' ')}');
    }
    return buffer.toString();
  }
}
