class CardModel {
  final String rank; // Пример: 'A', 'K', '9'
  final String suit; // Пример: '♠', '♥', '♦', '♣'

  CardModel({required this.rank, required this.suit});

  @override
  String toString() {
    return '$rank$suit';
  }
}